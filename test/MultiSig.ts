import {
  loadFixture, time
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("MultiSigLocktime", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployMultiSigContract() {
    const [owner, account1, account2] = await hre.ethers.getSigners();
    const MultiSig = await hre.ethers.getContractFactory("MultiSigTimeLock");
    const multiSig = await MultiSig.deploy([owner.address, account1.address, account2.address]);

    return { multiSig, owner, account1, account2 };
  }

  describe("Deployment", function () {
    it("Should be deployed by owner", async function () {
      const { multiSig, owner } = await loadFixture(deployMultiSigContract);

      expect(await multiSig.owners(0)).to.equal(owner.address);
      expect(await multiSig.contractBalance()).to.be.equal(0);
    });

    it("should have a valid address", async function () {
      const { multiSig } = await loadFixture(deployMultiSigContract);
      expect(await multiSig.getAddress()).to.not.equal(hre.ethers.ZeroAddress);
    });
  });

  describe("Deposit", function () {
    it("Should deposit funds into the contract", async function () {
        const { multiSig, owner } = await loadFixture(deployMultiSigContract);

        await expect(
            multiSig.connect(owner).deposit({ value: 1000n }) 
        ).to.emit(multiSig, "Deposited")
          .withArgs(1000n, 0); 

        const contractBalance = await hre.ethers.provider.getBalance(multiSig.target);
        expect(contractBalance).to.equal(1000n);
    });

    it("Should fail if deposit amount is 0", async function () {
      const { multiSig, owner } = await loadFixture(deployMultiSigContract);
      await expect(
        multiSig.connect(owner).deposit({ value: 0n })
      ).to.be.revertedWith("Deposit amount must be greater than zero");
    });

    it("Should check if deposit event is emitted", async function () {
      const { multiSig, owner } = await loadFixture(deployMultiSigContract);
      
      //const unlockTime = (await time.latest()) + 100;
  
      await expect(
          multiSig.connect(owner).deposit({ value: 10n }) 
      ).to.emit(multiSig, "Deposited"); 
    });

    it("Should increment tx counter", async function () {
      const { multiSig, owner } = await loadFixture(deployMultiSigContract);
      
      await multiSig.connect(owner).deposit({ value: 10n });
      expect(await multiSig.txCounter()).to.equal(1);
    });

    it("Should update contract balance on deposit", async function () {
      const { multiSig, owner } = await loadFixture(deployMultiSigContract);

      await multiSig.connect(owner).deposit({ value: 10n });

      expect(await multiSig.viewBalance()).to.equal(10n);

      const actualContractBalance = await hre.ethers.provider.getBalance(multiSig.target);
      expect(actualContractBalance).to.equal(10n);
    });
  });

    // it("Should fail if a non-owner deposits", async function () {
    //   const { multiSig, account2 } = await loadFixture(deployMultiSigContract);
  
    //   await expect(
    //       multiSig.connect(account2).deposit({ value: 10n })
    //   ).to.be.revertedWith("Only owners can call this function");
    // });
  
    // describe("Approve", function () {
    //   it("Should approve a transaction", async function () {
    //     const { multiSig, owner, account1 } = await loadFixture(deployMultiSigContract);

    //     const txId = await multiSig.txCounter();
    //     const addressTo = account1.address;
    //     const amount = 10n;

    //     await multiSig.connect(owner).approveTransaction(txId, addressTo, amount);
        
        
    // });
  

    describe("Withdraw", function () {
      it("Should withdraw funds from the contract", async function () {
          const { multiSig, owner } = await loadFixture(deployMultiSigContract);
          const amount = 1000n;
  
          await multiSig.connect(owner).deposit({ value: amount });
  
          const txId = await multiSig.txCounter() - 1n;
          await time.increase(864000);
          await multiSig.connect(owner).approveTransaction(txId, owner.address, amount);
          await multiSig.connect(owner).withdraw(txId, amount);
          expect(await hre.ethers.provider.getBalance(multiSig.target)).to.equal(0n);
      });
  });

  it("Should fail if a non-owner withdraws", async function () {
    const { multiSig, owner, account1 } = await loadFixture(deployMultiSigContract);
    const amount = 1000n;

    await multiSig.connect(owner).deposit({ value: amount });

    const txId = await multiSig.txCounter() - 1n;

    await time.increase(864000); 
    await multiSig.connect(owner).approveTransaction(txId, owner.address, amount);

    console.log("Checking if account1 is an owner...");
    try {
        for (let i = 0; i < 5; i++) {
            const ownerAddress = await multiSig.owners(i);
            console.log(`Owner ${i}: ${ownerAddress}`);
        }
    } catch (error) {
        console.log("No more owners found.");
    }

    await expect(
        multiSig.connect(account1).withdraw(txId, amount)
    ).to.be.revertedWith("Only owners can call this function");
});



    //   it("Should fail if the contract balance is less than the withdrawal amount", async function () {
    //     const { multiSig, owner } = await loadFixture(deployMultiSigContract);

    //     const txId = await multiSig.txCounter();
    //     const amount = 1000n;
    //     await multiSig.connect(owner).deposit({ value: 1000n });

    //     await expect(
    //         multiSig.connect(owner).withdraw(txId, amount + 1n)
    //     ).to.be.revertedWith("Insufficient funds");
    //   });
    });
 
 