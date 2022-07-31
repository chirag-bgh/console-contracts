// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import "../../access/AdminControl.sol";

import "../../core/IERC721CreatorCore.sol";
import "./ERC721CreatorExtension.sol";
import "./IERC721CreatorExtensionBurnable.sol";

/**
 * @dev Suggested implementation for extensions that want to receive onBurn callbacks
 * Mint tracks the creators/tokens created, and onBurn only accepts callbacks from
 * the creator of a token created.
 */
abstract contract ERC721CreatorExtensionBurnable is
    AdminControl,
    ERC721CreatorExtension,
    IERC721CreatorExtensionBurnable
{
    mapping(uint256 => address) private _tokenCreators;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, CreatorExtension, IERC165)
        returns (bool)
    {
        return
            interfaceId == LEGACY_ERC721_EXTENSION_BURNABLE_INTERFACE ||
            interfaceId == type(IERC721CreatorExtensionBurnable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev mint a token
     */
    function mint(address creator, address to) external adminRequired returns (uint256) {
        return _mint(creator, to);
    }

    /**
     * @dev batch mint a token
     */
    function mintBatch(
        address creator,
        address to,
        uint16 count
    ) external adminRequired returns (uint256[] memory) {
        return _mintBatch(creator, to, count);
    }

    function _mint(address creator, address to) internal returns (uint256) {
        require(
            ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId),
            "creator must implement IERC721CreatorCore"
        );
        uint256 tokenId = IERC721CreatorCore(creator).mintExtension(to);
        _tokenCreators[tokenId] = creator;
        return tokenId;
    }

    function _mint(
        address creator,
        address to,
        string memory uri
    ) internal returns (uint256) {
        require(
            ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId),
            "creator must implement IERC721CreatorCore"
        );
        uint256 tokenId = IERC721CreatorCore(creator).mintExtension(to, uri);
        _tokenCreators[tokenId] = creator;
        return tokenId;
    }

    function _mintBatch(
        address creator,
        address to,
        uint16 count
    ) internal returns (uint256[] memory tokenIds) {
        require(
            ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId),
            "creator must implement IERC721CreatorCore"
        );
        tokenIds = IERC721CreatorCore(creator).mintExtensionBatch(to, count);
        for (uint16 i = 0; i < tokenIds.length; i++) {
            _tokenCreators[tokenIds[i]] = creator;
        }
        return tokenIds;
    }

    function _mintBatch(
        address creator,
        address to,
        string[] memory uris
    ) internal returns (uint256[] memory tokenIds) {
        require(
            ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId),
            "creator must implement IERC721CreatorCore"
        );
        tokenIds = IERC721CreatorCore(creator).mintExtensionBatch(to, uris);
        for (uint16 i = 0; i < tokenIds.length; i++) {
            _tokenCreators[tokenIds[i]] = creator;
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721CreatorExtension-onBurn}.
     */
    function onBurn(address, uint256 tokenId) public virtual override {
        require(_tokenCreators[tokenId] == msg.sender, "Can only be called by token creator");
    }
}
