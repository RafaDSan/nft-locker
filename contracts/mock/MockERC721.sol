// SPD-License-Identifier: MIT
pragma solidity 0.8.26

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 public totalSupply;

    constructor() ERC721("MockERC721-LP", "ERC721-LP") {}

    function mint(address to, uint id) public {
        totalSupply++;
        _mint(to, id);
    }

    function tokenURI(
        uint256
    ) public view virtual override returns (string memory) {
        return "ipfs://QmWodCkovJk18U75g8Veg6rCnw7951vQvTjYfS7J3nMFma/";
    }
}