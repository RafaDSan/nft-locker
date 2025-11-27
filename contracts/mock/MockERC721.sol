// SPD-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 { // MockERC721 is a derived contract from ERC721, therefore ERC721 is its parent and Mock is inherting its logic
    uint256 public totalSupply;

    constructor() ERC721("Mock Uniswap v3 LP", "UNI-V3-POS") {} // When deployed, the constructor is executed once and not anymore
    // Settings these values into the contract's permanent storage in the moment of deploy

    function mint(address to, uint id) public {
        _mint(to, id); // For productin environment, an alternative is _safeMint to prevent users mistakes 
        // _safeMint introduces reentrancy attack which developers should update states before the mint happens due to external calls
        totalSupply++;
    }

    // The "virtual" keyword is placed in the "tokenURI" signature function coming frm the "ERC721" and it means we can change (override) it
    // in derived contracts (child contracts)
    function tokenURI(
        uint256
    ) public view virtual override returns (string memory) {
        return "ipfs://QmWodCkovJk18U75g8Veg6rCnw7951vQvTjYfS7J3nMFma/";
    }
}
