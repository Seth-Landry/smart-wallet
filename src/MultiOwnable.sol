// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Auth contract allowing multiple owners
/// identifies owners as bytes to allow for secp256r1 X,Y coordinates to
/// identify an owner.
/// Designed for use in smart account context.
contract MultiOwnable {
    /// @dev tracks the next owner to
    uint8 public ownerIndex;

    /// @dev Allows an owner to be idenfitied by a uint8.
    /// Passkey verifier does not recover the address, but requires
    /// the X,Y coordinates to be passed for verification.
    /// In the context of checking whether something was signed by an owner
    /// this means that the signature needs to include an identifier of the owner.
    /// In an effort to economize calldata, we use a uint8 rather than passing the
    /// X,Y coordinates.
    mapping(uint8 => bytes) public ownerAtIndex;
    mapping(bytes => bool) internal _isOwner;

    bytes32 private constant EMPTY = keccak256(abi.encode(""));

    error Unauthorized();

    event AddOwner(bytes indexed owner, bytes indexed addedBy, uint8 indexed index);
    event RemoveOwner(bytes indexed owner, bytes indexed removedBy, uint8 indexed index);

    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }

    /// @dev convenience function that can be used to add the first
    /// 255 owners.
    function addOwner(bytes calldata owner) public virtual onlyOwner {
        _addOwnerAtIndex(owner, ++ownerIndex);
    }

    /// @dev adds an owner, identified by a specific index
    /// reverts if ownerAtIndex[index] is set
    /// reverts if index > ownerIndex
    function addOwnerAtIndex(bytes calldata owner, uint8 index) public virtual onlyOwner {
        require(index <= ownerIndex, "invalid index");
        require(keccak256(ownerAtIndex[index]) == EMPTY, "invalid index");

        _addOwnerAtIndex(owner, index);
    }

    /// @dev removes an owner, identified by a specific index
    /// reverts if ownerAtIndex[index] is not `owner`
    function removeOwnerAtIndex(bytes calldata owner, uint8 index) public virtual onlyOwner {
        require(keccak256(owner) == keccak256(ownerAtIndex[index]), "invalid owner + index");
        delete _isOwner[owner];
        delete ownerAtIndex[index];

        // removedBy may be address(this) when used with smart account
        emit RemoveOwner(owner, abi.encode(msg.sender), index);
    }

    function isOwner(address account) public view virtual returns (bool) {
        return _isOwner[abi.encode(account)];
    }

    function isOwner(bytes calldata account) public view virtual returns (bool) {
        return _isOwner[account];
    }

    function isOwnerMemory(bytes memory account) public view virtual returns (bool) {
        return _isOwner[account];
    }

    function _initializeOwner(bytes[] calldata owners) internal virtual {
        for (uint256 i = 0; i < owners.length; i++) {
            _addOwnerAtIndex(owners[i], uint8(i));
        }
    }

    function _addOwnerAtIndex(bytes calldata owner, uint8 index) internal virtual {
        _isOwner[owner] = true;
        ownerAtIndex[index] = owner;

        emit AddOwner(owner, abi.encode(msg.sender), index);
    }

    /// @dev There is no logic in this contract
    /// to allow for address(this) to be msg.sender.
    /// This should be enabled in the inheriting contract
    /// to allow for a passkey owner to call these functions.
    function _checkOwner() internal view virtual {
        if (!isOwner(msg.sender)) if (msg.sender != address(this)) revert Unauthorized();
    }
}