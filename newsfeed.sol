// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Newsfeed {
    struct Post {
        address author;
        string content;
        int256 upvoteCount;
        int256 downvoteCount;
        string[] sourcePostIds;
        mapping(address => bool) hasVoted;
        uint256 etherAmount;
    }

    mapping(uint256 => Post) public posts;
    uint256 public postCount;

    event PostCreated(uint256 postId, address author, string content, int256 voteCount, uint256 etherAmount);
    event Voted(uint256 postId, address voter, int256 newUpvoteCount, int256 downvoteCount, uint256 etherReturned);

    function createPost(string memory _content, string[] memory _sourcePostIds) public payable {
        require(msg.value >= 500000, "Insufficient Ether sent");

        postCount++;
        Post storage newPost = posts[postCount];
        newPost.author = msg.sender;
        newPost.content = _content;
        newPost.upvoteCount = 0;
        newPost.downvoteCount = 0;
        newPost.etherAmount = msg.value;
        newPost.sourcePostIds = _sourcePostIds;

        emit PostCreated(postCount, msg.sender, _content, 0, msg.value);
    }

    function vote(uint256 _postId, bool _isUpvote) public {
        require(_postId > 0 && _postId <= postCount, "Invalid post ID");
        Post storage post = posts[_postId];

        require(msg.sender != post.author, "You cannot vote on your own post");
        require(!post.hasVoted[msg.sender], "You can only vote once on a post");

        // Calculate 10% of the remaining Ether
        uint256 etherToReturn = (post.etherAmount * 10) / 100;

        // Update the vote count based on the type of vote
        if (_isUpvote) {
            post.upvoteCount++;
        } else {
            post.downvoteCount++;
        }

        // Transfer Ether back to the voter
        payable(msg.sender).transfer(etherToReturn);

        // Update post details
        post.hasVoted[msg.sender] = true;
        post.etherAmount -= etherToReturn;

        emit Voted(_postId, msg.sender, post.upvoteCount, post.downvoteCount, etherToReturn);
    }

    function getVoteCount(uint256 _postId) public view returns (int256) {
        require(_postId > 0 && _postId <= postCount, "Invalid post ID");
        return posts[_postId].upvoteCount - posts[_postId].downvoteCount;
    }

    function getTrustFactor(uint256 _postId) public view returns (int256) {
        require(_postId > 0 && _postId <= postCount, "Invalid post ID");
        Post storage post = posts[_postId];
        int256 totalVotes = post.upvoteCount + post.downvoteCount;
        return (post.upvoteCount * 100) / totalVotes;
    }

    function getPost(uint256 _postId) public view returns (address, string memory, int256,int256, uint256, string[] memory) {
        require(_postId > 0 && _postId <= postCount, "Invalid post ID");
        Post storage post = posts[_postId];
        return (post.author, post.content, post.upvoteCount, post.downvoteCount, post.etherAmount, post.sourcePostIds);
    }

    
    function getAllPosts() public view returns (uint256[] memory, address[] memory, string[] memory, int256[] memory, int256[] memory, uint256[] memory, string[][] memory) {
        uint256[] memory postIds = new uint256[](postCount);
        address[] memory authors = new address[](postCount);
        string[] memory contents = new string[](postCount);
        int256[] memory upvoteCounts = new int256[](postCount);
        int256[] memory downvoteCounts = new int256[](postCount);
        uint256[] memory etherAmounts = new uint256[](postCount);
        string[][] memory sourcePostIds = new string[][](postCount);

        for (uint256 i = 1; i <= postCount; i++) {
            Post storage post = posts[i];
            postIds[i - 1] = i;
            authors[i - 1] = post.author;
            contents[i - 1] = post.content;
            upvoteCounts[i - 1] = post.upvoteCount;
            downvoteCounts[i - 1] = post.downvoteCount;
            etherAmounts[i - 1] = post.etherAmount;
            sourcePostIds[i - 1] = post.sourcePostIds;
        }

        return (postIds, authors, contents, upvoteCounts, downvoteCounts, etherAmounts, sourcePostIds);
    }

}
