// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;


interface IUniswapV2Errors {
    /**
     * @dev Revert with an error when an ERC20 token transfer reverts.
     *
     * @param token      The token for which the transfer was attempted.
     * @param to         The recipient of the attempted transfer.
     * @param amount     The amount for the attempted transfer.
     */
    error TokenTransferGenericFailure(
        address token,
        address to,
        uint256 amount
    );

    /**
     * @dev Revert with an error when an ERC20 token transfer returns a falsey
     *      value.
     *
     * @param token      The token for which the ERC20 transfer was attempted.
     * @param to         The recipient of the attempted ERC20 transfer.
     * @param amount     The amount for the attempted ERC20 transfer.
     */
    error BadReturnValueFromERC20OnTransfer(
        address token,
        address to,
        uint256 amount
    );
}