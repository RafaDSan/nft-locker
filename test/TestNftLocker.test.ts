import { expect } from "chai";
import { ethers } from "hardhat";
import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("NftLocker", function () {
  async function deployLockerFixture() {
    const [user, thief] = await ethers.getSigners();

    const MockERC721 = await ethers.getContractFactory("MockERC721");
    const mockNft = await MockERC721.deploy();

    const NftLocker = await ethers.getContractFactory("NftLocker");
    const locker = await NftLocker.deploy();

    return { locker, mockNft, user, thief };
  }

  describe("Deployment", function () {
    it("Should set the correct duration", async function () {
      const { locker } = await loadFixture(deployLockerFixture);
      expect(await locker.durationSeconds()).to.equal(120);
    });

    it("Should Correctly mint a Mock NFT", async function () {
      const { mockNft, user } = await loadFixture(deployLockerFixture);
      await mockNft.mint(user.address, 1);
      expect(await mockNft.ownerOf(1)).to.equal(user.address);
    });
  });

  describe("Locking NFTs", function () {
    it("Should fail if user does not approve contract first", async function () {
      const { locker, mockNft, user } = await loadFixture(deployLockerFixture);

      await mockNft.mint(user.address, 1);

      await expect(locker.connect(user).lockNft(mockNft.target, 1)).to.be
        .reverted;
    });

    it("Should allow user to lock an NFT", async function () {
      const { locker, mockNft, user } = await loadFixture(deployLockerFixture);

      await mockNft.mint(user.address, 1);

      await mockNft.connect(user).approve(locker.target, 1);

      await locker.connect(user).lockNft(mockNft.target, 1);

      expect(await mockNft.ownerOf(1)).to.equal(locker.target);

      const lockInfo = await locker.locks(mockNft.target, 1);
      expect(lockInfo.originalOwner).to.equal(user.address);
      expect(lockInfo.isLocked).to.be.true;
    });

    it("Should fail if address it not an ERC721", async function () {
      const { locker, user } = await loadFixture(deployLockerFixture);
      await expect(
        locker.connect(user).lockNft(user.address, 1),
      ).to.be.revertedWith("Address it not a contract");
    });
  });

  describe("Unlocking NFTs", function () {
    it("Should fail if trying to unlock too early", async function () {
      const { locker, mockNft, user } = await loadFixture(deployLockerFixture);

      await mockNft.mint(user.address, 1);
      await mockNft.connect(user).approve(locker.target, 1);
      await locker.connect(user).lockNft(mockNft.target, 1);

      await expect(
        locker.connect(user).unlockNft(mockNft.target, 1),
      ).to.be.revertedWith("Still locked. Wait for some time to pass.");
    });

    it("Should succeed after waiting 120 seconds", async function () {
      const { locker, mockNft, user } = await loadFixture(deployLockerFixture);

      await mockNft.mint(user.address, 1);
      await mockNft.connect(user).approve(locker.target, 1);
      await locker.connect(user).lockNft(mockNft.target, 1);

      await time.increase(121);

      await locker.connect(user).unlockNft(mockNft.target, 1);

      expect(await mockNft.ownerOf(1)).to.equal(user.address);

      const lockInfo = await locker.locks(mockNft.target, 1);
      expect(lockInfo.isLocked).to.be.false;
    });

    it("Should fail if another user tries to unlock", async function () {
      const { locker, mockNft, user, thief } =
        await loadFixture(deployLockerFixture);

      await mockNft.mint(user.address, 1);
      await mockNft.connect(user).approve(locker.target, 1);
      await locker.connect(user).lockNft(mockNft.target, 1);

      await time.increase(121);

      await expect(
        locker.connect(thief).unlockNft(mockNft.target, 1),
      ).to.be.revertedWith("Not the owner");
    });
  });
});
