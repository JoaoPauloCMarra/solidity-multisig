// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(address indexed owner, uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txId);
    event RevokeConfirmation(address indexed owner, uint256 indexed txId);
    event ExecuteTransaction(address indexed owner, uint256 indexed txId);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ThresholdChanged(uint256 threshold);

    error NotOwner();
    error TxNotExists();
    error TxAlreadyExecuted();
    error TxAlreadyConfirmed();
    error TxNotConfirmed();
    error ThresholdNotMet();
    error InvalidOwner();
    error OwnerExists();
    error OwnerNotExists();
    error InvalidThreshold();
    error TxFailed();
    error OwnersRequired();

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmCount;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public threshold;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyWallet() {
        _checkWallet();
        _;
    }

    modifier txExists(uint256 _txId) {
        _checkTxExists(_txId);
        _;
    }

    modifier notExecuted(uint256 _txId) {
        _checkNotExecuted(_txId);
        _;
    }

    modifier notConfirmed(uint256 _txId) {
        _checkNotConfirmed(_txId);
        _;
    }

    function _checkOwner() internal view {
        if (!isOwner[msg.sender]) revert NotOwner();
    }

    function _checkWallet() internal view {
        if (msg.sender != address(this)) revert NotOwner();
    }

    function _checkTxExists(uint256 _txId) internal view {
        if (_txId >= transactions.length) revert TxNotExists();
    }

    function _checkNotExecuted(uint256 _txId) internal view {
        if (transactions[_txId].executed) revert TxAlreadyExecuted();
    }

    function _checkNotConfirmed(uint256 _txId) internal view {
        if (isConfirmed[_txId][msg.sender]) revert TxAlreadyConfirmed();
    }

    constructor(address[] memory _owners, uint256 _threshold) {
        if (_owners.length == 0) revert OwnersRequired();
        if (_threshold == 0 || _threshold > _owners.length) revert InvalidThreshold();

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) revert InvalidOwner();
            if (isOwner[owner]) revert OwnerExists();

            isOwner[owner] = true;
            owners.push(owner);
        }

        threshold = _threshold;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submit(address _to, uint256 _value, bytes calldata _data) external onlyOwner returns (uint256) {
        uint256 txId = transactions.length;
        transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false, confirmCount: 0}));

        emit SubmitTransaction(msg.sender, txId, _to, _value, _data);
        return txId;
    }

    function confirm(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notConfirmed(_txId) {
        Transaction storage txn = transactions[_txId];
        txn.confirmCount += 1;
        isConfirmed[_txId][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txId);
    }

    function execute(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        Transaction storage txn = transactions[_txId];
        if (txn.confirmCount < threshold) revert ThresholdNotMet();

        txn.executed = true;

        (bool ok,) = txn.to.call{value: txn.value}(txn.data);
        if (!ok) revert TxFailed();

        emit ExecuteTransaction(msg.sender, _txId);
    }

    function revoke(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        if (!isConfirmed[_txId][msg.sender]) revert TxNotConfirmed();

        Transaction storage txn = transactions[_txId];
        txn.confirmCount -= 1;
        isConfirmed[_txId][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txId);
    }

    function addOwner(address _owner) external onlyWallet {
        if (_owner == address(0)) revert InvalidOwner();
        if (isOwner[_owner]) revert OwnerExists();

        isOwner[_owner] = true;
        owners.push(_owner);

        emit OwnerAdded(_owner);
    }

    function removeOwner(address _owner) external onlyWallet {
        if (!isOwner[_owner]) revert OwnerNotExists();
        if (owners.length - 1 < threshold) revert InvalidThreshold();

        isOwner[_owner] = false;

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }

        emit OwnerRemoved(_owner);
    }

    function changeThreshold(uint256 _threshold) external onlyWallet {
        if (_threshold == 0 || _threshold > owners.length) revert InvalidThreshold();
        threshold = _threshold;
        emit ThresholdChanged(_threshold);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txId)
        external
        view
        txExists(_txId)
        returns (address to, uint256 value, bytes memory data, bool executed, uint256 confirmCount)
    {
        Transaction storage txn = transactions[_txId];
        return (txn.to, txn.value, txn.data, txn.executed, txn.confirmCount);
    }
}
