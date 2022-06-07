// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7;

import { ERC4626, ERC20 } from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import "./interfaces/IRewardsController.sol";
import "./interfaces/IPoolAddressesProvider.sol";
import "./interfaces/IPool.sol";

/// @title ERC4626 interface
/// See: https://eips.ethereum.org/EIPS/eip-4626
contract Wrapper is ERC4626 {
    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.

    IPoolAddressesProvider public constant addressesProvider = IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    ERC20 public immutable aToken;

    IPool internal lastPool;

    constructor(
      ERC20 _asset,
      string memory _name,
      string memory _symbol
    ) ERC4626(_asset, _name, _symbol) {
      IPool pool = IPool(addressesProvider.getPool());
      lastPool = pool;
      aToken = ERC20(pool.getReserveData(address(_asset)).aTokenAddress);
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
      return asset.balanceOf(address(this));
    }

    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal Logic
    ////////////////////////////////////////////////////////*/
/// @notice The amount of shares that the vault would
    /// exchange for the amount of assets provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
      shares = assets * totalAssets()/this.totalSupply();
    }

    /// @notice The amount of assets that the vault would
    /// exchange for the amount of shares provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
      assets = totalAssets()/(this.totalSupply()/shares);
    }

    /// @notice Total number of underlying assets that can
    /// be deposited by `owner` into the Vault, where `owner`
    /// corresponds to the input parameter `receiver` of a
    /// `deposit` call.
    function maxDeposit(address owner) public view virtual override returns (uint256 maxAssets) {
      maxAssets = type(uint256).max - balanceOf[owner];
    }

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their deposit at the current block, given
    /// current on-chain conditions.
    function previewDeposit(uint256 assets) public view virtual override returns (uint256 shares) {
      shares = assets;
    }

    /// @notice Total number of underlying shares that can be minted
    /// for `owner`, where `owner` corresponds to the input
    /// parameter `receiver` of a `mint` call.
    function maxMint(address owner) public view virtual override returns (uint256 maxShares) {
      maxShares = type(uint256).max - balanceOf[owner];
    }

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their mint at the current block, given
    /// current on-chain conditions.
    function previewMint(uint256 shares) public view virtual override returns (uint256 assets) {
      assets = shares;
    }

    /// @notice Total number of underlying assets that can be
    /// withdrawn from the Vault by `owner`, where `owner`
    /// corresponds to the input parameter of a `withdraw` call.
    function maxWithdraw(address owner) public view virtual override returns (uint256 maxAssets) {
      uint256 assetBalance = asset.balanceOf(address(asset));
      uint256 userBalance = balanceOf[owner];
      maxAssets = userBalance > assetBalance ? assetBalance : userBalance;
    }

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256 shares) {
      shares = assets;
    }

    /// @notice Total number of underlying shares that can be
    /// redeemed from the Vault by `owner`, where `owner` corresponds
    /// to the input parameter of a `redeem` call.
    function maxRedeem(address owner) public view virtual override returns (uint256 maxShares) {
      maxShares = maxWithdraw(owner);
    }

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    function previewRedeem(uint256 shares) public view virtual override returns (uint256 assets) {
      assets = shares;
    }
}