export interface IContacts {
    id: number;
    display: string;
    number: string;
    avatar?: string;
}

export interface BankTransferDTO {
    amount: number;
    toAccount: string | IContacts;
    transferType: 'accountNumber' | 'contact';
}