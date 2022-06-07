// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

/* ---- Machine State ---- */

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;

/* ---- Function Calls ---- */

// abi.encodeWithSignature(
//     "BadReturnValueFromERC20OnTransfer(address,address,uint256)"
// )
uint256 constant ERC20_transfer_signature = (
    0xa9059cbb00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC20_transfer_sig_ptr = 0x0;
uint256 constant ERC20_transfer_to_ptr = 0x04;
uint256 constant ERC20_transfer_amount_ptr = 0x24;
uint256 constant ERC20_transfer_length = 0x44;

/* ---- Error Messages ---- */

// abi.encodeWithSignature(
//     "TokenTransferGenericFailure(address,address,uint256)"
// )
uint256 constant TokenTransferGenericFailure_error_signature = (
    0x5cdb152300000000000000000000000000000000000000000000000000000000
);
uint256 constant TokenTransferGenericFailure_error_sig_ptr = 0x0;
uint256 constant TokenTransferGenericFailure_error_token_ptr = 0x4;
uint256 constant TokenTransferGenericFailure_error_to_ptr = 0x24;
uint256 constant TokenTransferGenericFailure_error_amount_ptr = 0x44;
uint256 constant TokenTransferGenericFailure_error_length = 0x64;

// abi.encodeWithSignature(
//     "BadReturnValueFromERC20OnTransfer(address,address,uint256)"
// )
uint256 constant BadReturnValueFromERC20OnTransfer_error_signature = (
    0xdca74beb00000000000000000000000000000000000000000000000000000000
);
uint256 constant BadReturnValueFromERC20OnTransfer_error_sig_ptr = 0x0;
uint256 constant BadReturnValueFromERC20OnTransfer_error_token_ptr = 0x04;
uint256 constant BadReturnValueFromERC20OnTransfer_error_to_ptr = 0x24;
uint256 constant BadReturnValueFromERC20OnTransfer_error_amount_ptr = 0x44;
uint256 constant BadReturnValueFromERC20OnTransfer_error_length = 0x64;