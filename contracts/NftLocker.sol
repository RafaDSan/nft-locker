// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28; // What version to use?

import {IERC721} from "./interfaces/IERC721.sol";

contract NftLocker {
    uint256 public durationSeconds = 120;
  // Creating a new type to store variables (it is similar to Typescript Interface or a C struct)
  // Helps organize the mapping, instead of one mapping for variable we can use one mapping that fetchs all these variables
  struct LockData {
    address originalOwner;
    uint256 unlockTime;
    bool isLocked;
  }

  // Mapping: NFT Address -> Token ID -> Lock Data
  mapping(address => mapping(uint256 => LockData)) public locks;

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;


  // TO do: Study how mapping works under the hood

  // Good Practice: prefix as "_" in function paremeters to distinguish from global state variables
  function lockNft(
    address _nftAddress,
    uint256 _tokenId
  ) external {

    require(_nftAddress.code.length > 0, "Address it not a contract");

    try IERC721(_nftAddress).supportsInterface(_INTERFACE_ID_ERC721) returns (bool isSupported) {
      require(isSupported, "Target is not on ERC721 contract");
    } catch {
      revert("Contract does not suport ERC721");
    }

    require(!locks[_nftAddress][_tokenId].isLocked, "Item already locked");

    IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);

    locks[_nftAddress][_tokenId] = LockData({
        originalOwner: msg.sender,
        unlockTime: block.timestamp + durationSeconds,
        isLocked: true
    });
  }

  function unlockNft(address _nftAddress, uint256 _tokenId) external {
    LockData memory lock = locks[_nftAddress][_tokenId];

    require(lock.isLocked, "NFT is not locked");
    require(msg.sender == lock.originalOwner, "Not the owner");
    require(block.timestamp >= lock.unlockTime, "Still locked. Wait for some time to pass.");

    delete locks[_nftAddress][_tokenId];

    IERC721(_nftAddress).transferFrom(address(this), msg.sender, _tokenId);
  }

  function getLockInfo(address _nftAddress, uint256 _tokenId) external view returns (address owner, uint256 unlockTime, uint256 timeLeft) {
    LockData memory lock = locks[_nftAddress][_tokenId];

    uint256 timeRemaining = 0;
    if (lock.unlockTime > block.timestamp) {
        timeRemaining = lock.unlockTime - block.timestamp;
    }

    return (lock.originalOwner, lock.unlockTime, timeRemaining);
  }
}
