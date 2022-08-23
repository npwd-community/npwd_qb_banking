import { useCallback } from 'react';
import { useSnackbar } from '../snackbar/useSnackbar';
import { ServerPromiseResp } from '../types/common';
import fetchNui from '../utils/fetchNui';
import { BankTransferDTO } from '../types/bank'
import { useSetBankBalance } from '../atoms/bank-atoms';

interface BankAPIValue {
  transferMoney: (data: BankTransferDTO) => Promise<void>;
}

export const useBankAPI = (): BankAPIValue => {
  const { addAlert } = useSnackbar();
  const updateBalance = useSetBankBalance();

  const transferMoney = useCallback(
    async ({ amount, toAccount, transferType }: BankTransferDTO) => {
      const resp = await fetchNui<ServerPromiseResp<number>>("npwd:qb-banking:transferMoney", {
        amount,
        toAccount,
        transferType
      });

      if (resp.status !== 'ok') {
        return addAlert({
          message: 'Failed to transfer money',
          type: 'error',
        });
      }

      updateBalance(resp.data)

      addAlert({
        message: 'Successfully transfered money',
        type: 'success',
      });
    },
    [addAlert],
  );

  return { transferMoney };
};