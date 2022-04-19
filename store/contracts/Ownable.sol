// SPDX-License-Identifier: MIT

pragma solidity <8.0.0;

contract Ownable {
    address private owner;

    modifier isOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}