import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
    BigNumber,
    Contract,
    ContractFunction,
    ContractReceipt,
    ContractTransaction,
    Wallet,
  } from "ethers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import { parseEther } from "ethers/lib/utils";

describe("NFT", () => {
    type WalletWithAddress = Wallet & SignerWithAddress;
    
    // deployer as contract owner
    let owner: WalletWithAddress;
    // whitelist user
    let whitelistedUser: WalletWithAddress;
    // signerUser
    let signerUser: WalletWithAddress;
  
    // random buyer
    let holder: WalletWithAddress;
    // random nft seller
    let externalUser: WalletWithAddress;
  
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let res: any;
  
    let MUTUO: Contract;
  
    // value funded to signers by default
    const ethAmount: BigNumber = ethers.utils.parseEther("10000");
    // const newRes = ethers.utils.formatEther(res);
    // const formatRes = Number.parseFloat(newRes).toFixed(2).toString();
  
    beforeEach(async () => {
      const mutuo = await ethers.getContractFactory("InvestStartup");
  
      //before(async () => {
      [owner, whitelistedUser, signerUser, holder, externalUser] = await (ethers as any).getSigners();
      //});
      MUTUO = await mutuo.deploy();

      await MUTUO.deployed();

      });
      // sanity checks
  describe("Init", async () => {
    it("should initialize", async () => {
      expect(MUTUO).to.be.ok;
    });

    it("accounts have been funded", async () => {
      // can't be eq to ethAmount due to marketplace contract deployment cost
      res = await ethers.provider.getBalance(owner.address);

      expect(res.toString()).to.have.lengthOf(22);
      // console.log(res); // lengthOf = 22
      // console.log(ethAmount); // lengthOf = 23

      expect(await ethers.provider.getBalance(whitelistedUser.address)).to.eq(ethAmount);
      expect(await ethers.provider.getBalance(signerUser.address)).to.eq(ethAmount);
      expect(await ethers.provider.getBalance(holder.address)).to.eq(ethAmount);
    });

    // Init
    describe("Mint", async () => {
      it("Check initial mint cost Airdrop", async () => {
        
        // await MUTUO.connect(owner).mintAirdrp(holder.address);
        // //verify balanceOF
        // expect(await MUTUO.balanceOf(holder.address)).to.equal(1);
        
      });

      it("Mint payable and Paused", async () => {

        // await MUTUO.connect(owner).setPaused(false);

        // await MUTUO.connect(owner).mintOmnes({
        //   value: ethers.utils.parseEther("8"),});

        //   const balancebefore = await ethers.provider.getBalance(holder.address);
        //   console.log(balancebefore);

        //   await MUTUO.connect(owner).withdrawPayments(holder.address);

        //   const balanceAfter = await ethers.provider.getBalance(holder.address);
        //   console.log(balanceAfter);

      });

    });
});

});
