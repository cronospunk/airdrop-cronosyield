// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "./MerkleProof.sol";

contract Airdrop is Ownable {

    /// @dev Where all the tokens not claimed in the airdrop go
    address public immutable _treasuryAddress;

    IERC20 public token;
    IERC721 public nft;

    using BitMaps for BitMaps.BitMap;

    bytes32 public merkleRoot;
    BitMaps.BitMap private claimed;

    uint256 public CPYPerPunk = 10 ether;

    event AirdropCompleted(address recipient, uint amount, uint date);

    constructor(address _token, address _nft, address treasuryAddress) {
        token = IERC20(_token);
        nft = IERC721(_nft);
        _treasuryAddress = treasuryAddress;
    }

    function claimAirdrop(bytes32[] calldata merkleProof) external {
         bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        (bool valid, uint256 index) = MerkleProof.verify(
            merkleProof,
            merkleRoot,
            leaf
        );
        require(valid, "Not a CronosPunk holder");

        // must not have claimed already
        require(!isClaimed(index), "Already claimed airdrop");

        // save that user claimed
        claimed.set(index);

        uint256 allocation = getAllocation(msg.sender); 

        token.transferFrom(address(this), msg.sender, allocation);

        emit AirdropCompleted(msg.sender, allocation, block.timestamp);
    }

    function getAllocation(address _account) public view returns (uint256) {
        uint256 balance = nft.balanceOf(_account);

        // Compute the allocation
        return CPYPerPunk * balance;
    }

    /**
     * @dev Sets the merkle root.
     * @param _merkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    
    /**
     * @dev Collect unclaimed tokens after airdrop.
     */
    function sweep() external onlyOwner {
        token.transferFrom(address(this), _treasuryAddress, token.balanceOf(address(this)));
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param index The index into the merkle tree.
     */
    function isClaimed(uint256 index) public view returns (bool) {
        return claimed.get(index);
    }
  
}