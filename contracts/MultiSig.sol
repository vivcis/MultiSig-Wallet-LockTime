// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MultiSigTimeLock {

    enum Status{
        SENT,
        DEPOSITED,
        APPROVED,
        WITHDRAWN,
        PENDING
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
        uint256 noOfApproval;
    
    }

    // mapping(address => uint256) public balances;
    mapping(uint256 => Transaction) public txId;
    mapping(uint256 => ApproveWithdrawal) public approveWithdrawal;
    mapping(uint256 => mapping(address => bool)) public hasApproved;
    
   // mapping(address => Transaction[]) public transactions;

    address[] public owners;

    uint256 public  QUOROM =  owners.length * 51 / 100;

    uint256 public contractBalance;

    uint256 public approveWithdrawalId;

    uint256 public txCounter;

    event Deposited(uint256 indexed _amount, uint256 _Id);
    event Approved(uint256 indexed _transactionId);
    event Withdrawn(uint256 indexed _amount, uint256 _Id);

    constructor(address[] memory _owners){
        owners = _owners;
    }

modifier onlyOwners() {
    bool isOwner = false;

    for (uint i = 0; i < owners.length; i++) {
        if (owners[i] == msg.sender) {
            isOwner = true;
            break; 
        }
    }
    require(isOwner, "Only owners can call this function");
    _;
}


function getOwners() external view returns (address[] memory) {
    return owners;
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

    function deposit() external payable onlyOwners {
        require(msg.sender != address(0), "Address zero not allowed");
        require(msg.value > 0, "Deposit amount must be greater than zero");

        uint256 transactionId = txCounter; 

        txId[transactionId] = Transaction({
            amount: msg.value,
            unlockTime: block.timestamp + 10 days,
            currentTime: block.timestamp,
            sent: false, 
            status: Status.DEPOSITED
        });

        txCounter += 1;

       contractBalance += msg.value;

        emit Deposited(msg.value, transactionId);
    }

   
    function approveTransaction(uint256 _transactionId, address _to, uint256 _amount) external {
    require(block.timestamp >= txId[_transactionId].unlockTime, "Transaction not yet unlocked");
    require(txId[_transactionId].status == Status.DEPOSITED, "Transaction must be in DEPOSITED state");

    txId[_transactionId].status = Status.APPROVED;

    uint256 _approveWithdrawlId = approveWithdrawalId + 1;

    require(!approveWithdrawal[_approveWithdrawlId].approved, "Transaction already approved");
    require(!hasApproved[_approveWithdrawlId][msg.sender], "Already approved by this user");
  
    if (approveWithdrawal[_approveWithdrawlId].noOfApproval == 0) {
        approveWithdrawal[_transactionId] = ApproveWithdrawal({
            to: _to,
            amount: _amount,
            approved: true,
            status: Status.APPROVED,
            noOfApproval: 1
        });
    } else {
        approveWithdrawal[_approveWithdrawlId].noOfApproval += 1;
    }
    txId[_transactionId].status = Status.APPROVED;

    hasApproved[_approveWithdrawlId][msg.sender] = true;

    if (approveWithdrawal[_approveWithdrawlId].noOfApproval >= QUOROM) {
        approveWithdrawal[_approveWithdrawlId].approved = true;
        approveWithdrawal[_approveWithdrawlId].status = Status.APPROVED;
    }

    approveWithdrawalId = _approveWithdrawlId;

    emit Approved(_transactionId);
   }

    function withdraw(uint256 _txId, uint256 _amount) external onlyOwners {
        require(msg.sender != address(0), "Address zero not allowed");
        require(txId[_txId].status == Status.APPROVED, "Transaction not yet approved");
        require(block.timestamp >= txId[_txId].unlockTime, "Transaction not yet unlocked");
        require(txId[_txId].amount == _amount, "Amount does not match transaction amount");
        require(address(this).balance >= _amount, "Insufficient balance");
        require(!txId[_txId].sent, "Transaction already processed");

        txId[_txId].sent = true;

        // ✅ Ensure recipient address is valid
        address recipient = approveWithdrawal[_txId].to;
        require(recipient != address(0), "Invalid recipient");

        // ✅ Transfer funds to the approved recipient
        payable(recipient).transfer(_amount);

        emit Withdrawn(_amount, _txId);
    }


    function viewBalance() external view returns(uint256){
        return contractBalance;
    }
    
}
