export interface IContacts {
    id: number;
    display: string;
    number: string;
    avatar?: string;
}

export interface BankTransferDTO {
    amount: number;
    toAccount: string | IContacts;
    transferType: "accountNumber" | "contact";
}

export interface IInvoice {
    id: number;
    citizenid: string;
    amount: number;
    society: string;
    sender: string;
    sendercitizenid: string;
}