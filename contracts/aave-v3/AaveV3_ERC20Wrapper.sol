// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7;

import {ERC4626, ERC20, SafeTransferLib} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import "./interfaces/IRewardsController.sol";
import "./interfaces/IPoolAddressesProvider.sol";
import "./interfaces/IPool.sol";

/// @title ERC4626 interface
/// See: https://eips.ethereum.org/EIPS/eip-4626
contract AaveV3_ERC20Wrapper is ERC4626 {
    using SafeTransferLib for ERC20;

    error UnsupportedUnderlying(address underlying);

    IPoolAddressesProvider public constant addressesProvider =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    ERC20 public immutable aToken;

    IPool internal lastPool;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset, _name, _symbol) {
        IPool pool = IPool(addressesProvider.getPool());
        lastPool = pool;
        address aTokenAddress = pool
            .getReserveData(address(_asset))
            .aTokenAddress;
        if (aTokenAddress == address(0)) {
            revert UnsupportedUnderlying(address(_asset));
        }
        aToken = ERC20(aTokenAddress);
        _asset.approve(address(pool), type(uint256).max);
    }

    function getPool() internal returns (IPool pool) {
        pool = IPool(addressesProvider.getPool());
        if (pool != lastPool) {
            asset.approve(address(lastPool), 0);
            asset.approve(address(pool), type(uint256).max);
            lastPool = pool;
        }
    }

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalAssets() public view virtual override returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeMint(uint256 assets) internal virtual {
        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);
        // Get current Aave V3 pool contract
        IPool pool = getPool();
        // Deposit assets
        pool.supply(address(asset), assets, address(this), 0);
    }

    function afterBurn(uint256 assets, address to) internal virtual {
          // Get current Aave V3 pool contract
          IPool pool = getPool();
          // Withdraw assets
          pool.withdraw(address(asset), assets, to);
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        beforeMint(assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual override returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        beforeMint(assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }
        afterBurn(assets, receiver);

        _burn(owner, shares);


        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        _burn(owner, shares);

        afterBurn(assets, receiver);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*////////////////////////////////////////////////////////
                      Vault Accounting Logic
    ////////////////////////////////////////////////////////*/

    /// @notice Total number of underlying assets that can
    /// be deposited by `owner` into the Vault, where `owner`
    /// corresponds to the input parameter `receiver` of a
    /// `deposit` call.
    function maxDeposit(address owner)
        public
        view
        virtual
        override
        returns (uint256 maxAssets)
    {
        maxAssets = type(uint256).max - balanceOf[owner];
    }

    /// @notice Total number of underlying shares that can be minted
    /// for `owner`, where `owner` corresponds to the input
    /// parameter `receiver` of a `mint` call.
    function maxMint(address owner)
        public
        view
        virtual
        override
        returns (uint256 maxShares)
    {
        maxShares = type(uint256).max - balanceOf[owner];
    }

    /// @notice Total number of underlying assets that can be
    /// withdrawn from the Vault by `owner`, where `owner`
    /// corresponds to the input parameter of a `withdraw` call.
    function maxWithdraw(address owner)
        public
        view
        virtual
        override
        returns (uint256 maxAssets)
    {
        uint256 assetBalance = asset.balanceOf(address(asset));
        uint256 userBalance = balanceOf[owner];
        maxAssets = userBalance > assetBalance ? assetBalance : userBalance;
    }

    /// @notice Total number of underlying shares that can be
    /// redeemed from the Vault by `owner`, where `owner` corresponds
    /// to the input parameter of a `redeem` call.
    function maxRedeem(address owner)
        public
        view
        virtual
        override
        returns (uint256 maxShares)
    {
        maxShares = maxWithdraw(owner);
    }
}
