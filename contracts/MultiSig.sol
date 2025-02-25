// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MultiSigTimeLock {

    enum Status{
        SENT;
        DEPOSITED;
        APPROVED;
        WITHDRAWN;
    }

    struct Transaction {
        // address to;
        uint256 amount;
        uint256 unlockTime;
        uint256 currentTime;
        bool sent;
        Status status;
    }

    struct ApproveWithdrawal {
        address to;
        uint256 amount;
        bool approved;
        Status status;
    }

    mapping(address => uint256) public balances;
    mapping(uint256 => Transaction) public txId;
    mapping(uint256 => ApproveWithdrawal) public approveWithdrawal;
   // mapping(address => Transaction[]) public transactions;

    address[] public owners;

    uint256 public constant QUOROM =  owners.length * 51 / 100;

    uint256 public contractBalance;

    uint256 public approveWithdrawalId;

    event Deposited(uint256 indexed _amount, uint256 _Id);
    event Approved(uint256 indexed _transactionId);
    event Withdrawn(uint256 indexed _amount, uint256 _Id);

    constructor(address[] memory _owners){
        owners = _owners
    }

    modifier onlyOwners(){
        bool owner = false;

        for(uint i = 0; i < owners.length; i++){
            if(owners[i] == msg.sender){
                owner = true;
            }
        }
        require(owner == true, "Only owners can call this function");
        _;
    }

    function addUsers (address _user) external onlyOwners {
        require(msg.sender == owners[0], "Only owner can add users");
        owners.push(_user);
    }

    function removeUsers (address _user) external onlyOwners {
        require(msg.sender == owners[0], "Only owner can remove users");

        for(uint i = 0; i < owners.length; i++){
            if(owners[i] == _user){
                delete owners[i];
            }
        }
    }

    function deposit() external payable onlyOwners{
        address contractBalance
        require(balances[msg.sender] > msg.value, "insufficient balance");
        require(msg.sender != address(0), "address zero not allowed");

        uint256 transactionId;

        txId[transactionId] = Transaction{
            amount = msg.value;
            unlockTime = block.timestamp + 10 days;
            currentTime = block.timestamp;
            sent = true;
            status = status.DEPOSITED;
        }

        transactionId += 1;

        contractBalance += msg.value;

        emit Deposited(msg.value, transactionId)
    }

    function viewBalance() external view returns(uint256){
        return contractBalance;
    }

    function approveTransaction(uint256 _transactionId) external {

        uint256 _approveWithdrawlId = approveWithdrawalId + 1;
        require(block.timestamp >= txId[_transactionId].unlockTime, "Transaction not yet unlocked");
        require(msg.sender != address(0), "address zero not allowed");
        require(QUOROM > 0, "Quorom not met");
        require(approveWithdrawal[_approveWithdrawlId].approved == false, "Transaction already approved");

        ApproveWithdrawal memory approveWithdrawal = _ApprovalWithdrawal({
            to : approveWithdrawal[_approveWithdrawlId].to,
            amount : approveWithdrawal[_approveWithdrawlId].amount,
            approved : true,
            status : Status.APPROVED
        });

        approveWithdrawalId += 1;

        emit Approved(_transactionId);

        //require(txId[_transactionId].status == Status.APPROVED, "Transaction already approved");

        // contractBalance -= transaction.amount;

    }

    function withdraw(uint256 _txId, uint256 _amount) external onlyOwners {
        require(msg.sender != address(0), "address zero not allowed");
        require(contractBalance >= _amount, "Insufficient balance");
        require(txId[_txId].amount == _amount, "Amount does not match transaction amount");
        require(txId[_txId].status == Status.APPROVED, "Transaction not yet approved");
        require(block.timestamp >= txId[_txId].unlockTime, "Transaction not yet unlocked");
        
        contractBalance -= _amount;

        ApproveWithdrawal memory _approveWithdrawal = approveWithdrawal(_txId);

        _approveWithdrawal.to.transfer(_amount);

        emit Withdrawn(_amount, _txId);
    }
    
}
