//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";

contract SoftStakingSystem {
    using SafeMath for uint256;

    ERC721 public nftContract;
    uint256 public rewardRate;
    uint256 public totalRewards;

    struct User {
        uint256 stakedNFTBalance;
        uint256 rewardBalance;
    }

    mapping(address => User) public users;

    constructor(address _nftContractAddress, uint256 _rewardRate) {
        nftContract = ERC721(_nftContractAddress);
        rewardRate = _rewardRate;
    }

    function registerUser() external {
        require(
            users[msg.sender].stakedNFTBalance == 0,
            "User already registered"
        );

        users[msg.sender] = User(0, 0);
    }

    function stakeNFT(uint256 _tokenId) external {
        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );

        // Verify that the _tokenId exists in the NFT contract
        require(nftContract.exists(_tokenId), "Invalid NFT token ID");

        // Transfer NFT to contract
        try nftContract.safeTransferFrom(msg.sender, address(this), _tokenId) {
            // Increment stakedNFTBalance
            users[msg.sender].stakedNFTBalance++;
        } catch (bytes memory error) {
            revert(string(error));
        }
    }

    function unstakeNFT(uint256 _tokenId) external {
        require(
            nftContract.ownerOf(_tokenId) == address(this),
            "This NFT is not staked"
        );

        // Transfer NFT back to owner
        nftContract.safeTransferFrom(address(this), msg.sender, _tokenId);

        users[msg.sender].stakedNFTBalance = users[msg.sender]
            .stakedNFTBalance
            .sub(1);
    }

    function calculateReward(address _user) internal view returns (uint256) {
        uint256 stakedNFTBalance = users[_user].stakedNFTBalance;

        if (stakedNFTBalance >= 10001) {
            rewardRate = 1;
        } else if (stakedNFTBalance >= 8001) {
            rewardRate = 1.5;
        } else if (stakedNFTBalance >= 6001) {
            rewardRate = 2;
        } else if (stakedNFTBalance >= 4001) {
            rewardRate = 2.5;
        } else if (stakedNFTBalance >= 2001) {
            rewardRate = 3;
        } else if (stakedNFTBalance >= 1001) {
            rewardRate = 3.5;
        } else if (stakedNFTBalance >= 501) {
            rewardRate = 4;
        } else if (stakedNFTBalance >= 101) {
            rewardRate = 4.5;
        } else if (stakedNFTBalance >= 61) {
            rewardRate = 5;
        } else {
            rewardRate = 8;
        }

        return stakedNFTBalance.mul(rewardRate);
    }

    function claimReward() external {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards to claim");

        users[msg.sender].rewardBalance = users[msg.sender].rewardBalance.add(
            reward
        );
        totalRewards = totalRewards.sub(reward);
    }

    function viewStakedNFTs(
        address _user
    ) external view returns (uint256[] memory) {
        uint256[] memory stakedNFTs = new uint256[](
            users[_user].stakedNFTBalance
        );

        // Logic to fetch the staked NFTs of the user
        uint256 count = 0;
        for (uint256 i = 0; i < users[_user].nfts.length; i++) {
            if (users[_user].nfts[i].isStaked) {
                stakedNFTs[count] = users[_user].nfts[i].tokenId;
                count++;
            }
        }

        return stakedNFTs;
    }

    function viewRewardBalance(address _user) external view returns (uint256) {
        return users[_user].rewardBalance;
    }

    function viewTotalRewards() external view returns (uint256) {
        return totalRewards;
    }

    function transferNFT(address _to, uint256 _tokenId) external {
        require(
            nftContract.ownerOf(_tokenId) == address(this),
            "This NFT is not staked"
        );

        nftContract.safeTransferFrom(address(this), _to, _tokenId);
    }

    function emergencyWithdraw(uint256 _tokenId) external {
        require(
            nftContract.ownerOf(_tokenId) == address(this),
            "This NFT is not staked"
        );

        // Transfer NFT back to owner
        nftContract.safeTransferFrom(address(this), msg.sender, _tokenId);

        uint256 reward = calculateReward(msg.sender);
        if (reward > 0) {
            users[msg.sender].rewardBalance = users[msg.sender]
                .rewardBalance
                .add(reward);
            totalRewards = totalRewards.sub(reward);
        }

        users[msg.sender].stakedNFTBalance = users[msg.sender]
            .stakedNFTBalance
            .sub(1);
    }
}
