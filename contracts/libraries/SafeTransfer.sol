// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./Constants.sol";

contract SafeTransfer {
  function safeTransfer(address token, address to, uint256 amount) internal {
    assembly {
      // Write calldata to the free memory pointer, but restore it later.
      let memPointer := mload(FreeMemoryPointerSlot)

      // Write transfer calldata into memory, starting with function selector.
      mstore(ERC20_transfer_sig_ptr, ERC20_transfer_signature)
      mstore(ERC20_transfer_to_ptr, to)
      mstore(ERC20_transfer_amount_ptr, amount)

      // Make call & copy up to 32 bytes of return data to scratch space.
      let callStatus := call(
        gas(),
        token,
        0,
        ERC20_transfer_sig_ptr,
        ERC20_transfer_length,
        0,
        0x20
      )

      // Determine whether transfer was successful using status & result.
      let success := and(
        // Set success to whether the call reverted, if not check it
        // either returned exactly 1 (can't just be non-zero data), or
        // had no return data.
        or(
          and(eq(mload(0), 1), gt(returndatasize(), 31)),
          iszero(returndatasize())
        ),
        callStatus
      )

      // If the transfer failed:
      if iszero(success) {
        // If it was due to a revert:
        if iszero(callStatus) {
          // If it returned a message, bubble it up
          if returndatasize() {
            // Copy returndata to memory; overwrite
            // existing memory.
            returndatacopy(0, 0, returndatasize())

            // Revert, specifying memory region with
            // copied returndata.
            revert(0, returndatasize())
          }

          // Otherwise revert with a generic error message.
          mstore(
            TokenTransferGenericFailure_error_sig_ptr,
            TokenTransferGenericFailure_error_signature
          )
          mstore(TokenTransferGenericFailure_error_token_ptr, token)
          mstore(TokenTransferGenericFailure_error_to_ptr, to)
          mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
          revert(
            TokenTransferGenericFailure_error_sig_ptr,
            TokenTransferGenericFailure_error_length
          )
        }

        // Otherwise revert with a message about the token
        // returning false.
        mstore(
          BadReturnValueFromERC20OnTransfer_error_sig_ptr,
          BadReturnValueFromERC20OnTransfer_error_signature
        )
        mstore(
          BadReturnValueFromERC20OnTransfer_error_token_ptr,
          token
        )
        mstore(
          BadReturnValueFromERC20OnTransfer_error_to_ptr,
          to
        )
        mstore(
          BadReturnValueFromERC20OnTransfer_error_amount_ptr,
          amount
        )
        revert(
          BadReturnValueFromERC20OnTransfer_error_sig_ptr,
          TokenTransferGenericFailure_error_length
        )
      }

      // Restore the original free memory pointer.
      mstore(FreeMemoryPointerSlot, memPointer)

      // Restore the zero slot to zero.
      mstore(ZeroSlot, 0)
    }
  }
}