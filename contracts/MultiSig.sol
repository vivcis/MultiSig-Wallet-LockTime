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

    mapping(address => uint256) public balances;
    mapping(uint256 => Transaction) public txId;
   // mapping(address => Transaction[]) public transactions;

    address[] public owners;

    uint256 public constant QUOROM =  owners.length * 51 / 100;

    uint256 public contractBalance;

    event Deposited(uint256 indexed _amount, uint256 _Id);

    constructor(address _owners){
        owners = _owners
    }

    function deposit() external payable{
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
        require(block.timestamp >= txId[_transactionId].unlockTime, "Transaction not yet unlocked");
        require(msg.sender != address(0), "address zero not allowed");
        require(QUOROM > 0, "Quorom not met");

        
        //require(txId[_transactionId].status == Status.APPROVED, "Transaction already approved");

        // contractBalance -= transaction.amount;

    }

    // uint public unlockTime;
    // address payable public owner;

    // event Withdrawal(uint amount, uint when);

    // constructor(uint _unlockTime) payable {
    //     require(
    //         block.timestamp < _unlockTime,
    //         "Unlock time should be in the future"
    //     );

    //     unlockTime = _unlockTime;
    //     owner = payable(msg.sender);
    // }

    // function withdraw() public {
    //     // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
    //     // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

    //     require(block.timestamp >= unlockTime, "You can't withdraw yet");
    //     require(msg.sender == owner, "You aren't the owner");

    //     emit Withdrawal(address(this).balance, block.timestamp);

    //     owner.transfer(address(this).balance);
    // }
}
