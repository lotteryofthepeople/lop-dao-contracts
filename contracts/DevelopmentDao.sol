// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IShareHolderDao.sol";
import "./libs/types.sol";

contract DevelopmentDao is Ownable {
    // share holder dao address
    address public shareHolderDao;

    // product dao address
    address public productDao;

    // minimum vote number
    uint256 public minVote;

    /**
     * @param _minVote min vote number
     **/
    event MinVoteUpdated(uint256 _minVote);

    /**
     * @param prev previous shareholder address
     * @param next next shareholder address
     * @dev emitted when dupdate share holder dao address by only owner
     **/
    event ShareHolderDaoUpdated(address indexed prev, address indexed next);

    /**
     * @param prev previous product dao address
     * @param next next product dao address
     * @dev emitted when dupdate product dao address by only owner
     **/
    event ProductDaoUpdated(address indexed prev, address indexed next);

    /**
     * @param _shareHolderDao share holder dao address
     * @param _productDao product dao address
     * @param _minVote min vote number to execute
     **/
    constructor(
        address _shareHolderDao,
        address _productDao,
        uint256 _minVote
    ) {
        require(
            _shareHolderDao != address(0),
            "DevelopmentDao: share holder dao address should not be the zero address"
        );
        require(
            _productDao != address(0),
            "DevelopmentDao: product dao address should not be the zero address"
        );
        require(
            _minVote > 0,
            "DevelopmentDao: min vote should be greater than the zero"
        );

        shareHolderDao = _shareHolderDao;
        productDao = _productDao;
        minVote = _minVote;

        emit ShareHolderDaoUpdated(address(0), shareHolderDao);
        emit ProductDaoUpdated(address(0), productDao);
        emit MinVoteUpdated(minVote);
    }

    /**
     * @param _shareHolderDao new shoare holder dao address
     **/
    function setShareHolderDao(address _shareHolderDao) external onlyOwner {
        require(
            _shareHolderDao != address(0),
            "DevelopmentDao: share holder dao address should not be the zero address"
        );

        address _prevShareHolderDao = shareHolderDao;

        shareHolderDao = _shareHolderDao;

        emit ShareHolderDaoUpdated(_prevShareHolderDao, _shareHolderDao);
    }

    /**
     * @param _minVote min vote number
     **/
    function setMinVote(uint256 _minVote) external onlyOwner {
        require(
            _minVote > 0,
            "DevelopmentDao: minVote should be greater than the zero"
        );

        minVote = _minVote;

        emit MinVoteUpdated(minVote);
    }

    /**
     * @dev get LOP address from ShareHolderDao
     **/
    function getLOP() public returns (address) {
        return IShareHolderDao(shareHolderDao).getLOP();
    }

    /**
     * @dev get vLOP address from ShareHolderDao
     **/
    function getVLOP() public returns (address) {
        return IShareHolderDao(shareHolderDao).getVLOP();
    }
}
