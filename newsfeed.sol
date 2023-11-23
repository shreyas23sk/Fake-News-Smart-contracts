// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Newsfeed {
    struct Post {
        address author;
        string content;
        int256 upvoteCount;
        int256 downvoteCount;
        uint256[] sourcePostIds;
        mapping(address => bool) hasVoted;
        uint256 etherAmount;
    }

    mapping(uint256 => Post) public posts;
    uint256 public postCount;

    event PostCreated(uint256 postId, address author, string content, int256 voteCount, uint256 etherAmount);
    event Voted(uint256 postId, address voter, int256 newUpvoteCount, int256 downvoteCount, uint256 etherReturned);

    function createPost(string memory _content, uint256[] memory _sourcePostIds) public payable {
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

    function getPost(uint256 _postId) public view returns (address, string memory, int256,int256, uint256, uint256[] memory) {
        require(_postId > 0 && _postId <= postCount, "Invalid post ID");
        Post storage post = posts[_postId];
        return (post.author, post.content, post.upvoteCount, post.downvoteCount, post.etherAmount, post.sourcePostIds);
    }
}
