local QBCore = exports["qb-core"]:GetCoreObject()
local bannedCharacters = { "%", "$", ";" }

local function round(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces > 0 then
        local mult = 10 ^ numDecimalPlaces
        return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
end

QBCore.Functions.CreateCallback("npwd:qb-banking:GetBankBalance", function(source, cb)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local balance = Player.Functions.GetMoney("bank")
	if not balance then
		return cb(false)
	end
	cb(balance)
end)

QBCore.Functions.CreateCallback("npwd:qb-banking:getAccountNumber", function(source, cb)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local accountNumber = Player.PlayerData.charinfo.account
	if not accountNumber then
		return cb(false)
	end
	cb(accountNumber)
end)

QBCore.Functions.CreateCallback("npwd:qb-banking:getContacts", function(source, cb)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local contacts = MySQL.query.await(
		"SELECT * FROM npwd_phone_contacts WHERE identifier = ? ORDER BY display ASC",
		{ Player.PlayerData.citizenid }
	)
	if not contacts then
		return cb(false)
	end
	cb(contacts)
end)

QBCore.Functions.CreateCallback("npwd:qb-banking:getInvoices", function(source, cb)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local invoices = MySQL.query.await(
		"SELECT * FROM phone_invoices WHERE citizenid = ?",
		{ Player.PlayerData.citizenid }
	)
	if not invoices then
		return cb(false)
	end
	cb(invoices)
end)

QBCore.Functions.CreateCallback("npwd:qb-banking:declineInvoice", function(source, cb, data)
	local src = source
	local invoiceId = data
	local Player = QBCore.Functions.GetPlayer(src)
	local result = MySQL.query.await(
		"DELETE FROM phone_invoices WHERE citizenid = ? AND id = ?",
		{ Player.PlayerData.citizenid, invoiceId }
	)
	if not result then
		return cb(false)
	end
	cb(true)
end)

QBCore.Functions.CreateCallback("npwd:qb-banking:payInvoice", function(source, cb, data)
	local src = source
	local SenderPlayer = QBCore.Functions.GetPlayerByCitizenId(data.sendercitizenid)
	local Player = QBCore.Functions.GetPlayer(src)
	local society = data.society
	local amount = tonumber(data.amount)
	local invoiceId = data.id
	local invoiceMailData = {}
	local balance = Player.Functions.GetMoney("bank")

	if balance < amount then
		return cb(false) --not enough money
	end

	Player.Functions.RemoveMoney('bank', amount, "paid-invoice")

	if not Config.BillingCommissions[society] then
		invoiceMailData = {
			sender = 'Billing Department',
			subject = 'Bill Paid',
			message = string.format('%s %s paid a bill of $%s', Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, amount)
		}
	end	

	if Config.BillingCommissions[society] then
		local commission = round(amount * Config.BillingCommissions[society])
		invoiceMailData = {
            sender = 'Billing Department',
            subject = 'Bill Paid',
            message = string.format('You received a commission check of $%s when %s %s paid a bill of $%s.', commission, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, amount)
        }
		if SenderPlayer then
			SenderPlayer.Functions.AddMoney('bank', commission)
		else
			local RecieverDetails = MySQL.query.await("SELECT money FROM players WHERE citizenid = ?", { data.sendercitizenid })
			local RecieverMoney = json.decode(RecieverDetails[1].money)
			RecieverMoney.bank = (RecieverMoney.bank + commission)
			MySQL.update(
				"UPDATE players SET money = ? WHERE citizenid = ?",
				{ json.encode(RecieverMoney), data.sendercitizenid }
			)
		end
		amount = amount - commission
	end
	TriggerEvent('qb-phone:server:sendNewMailToOffline', data.sendercitizenid, invoiceMailData)
	exports['qb-management']:AddMoney(society, amount)
	MySQL.query('DELETE FROM phone_invoices WHERE id = ?', {invoiceId})
	local newBalance = Player.Functions.GetMoney("bank")
	cb(newBalance)
end)

QBCore.Functions.CreateCallback("npwd:qb-banking:transferMoney", function(source, cb, amount, toAccount, transferType)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local balance = Player.Functions.GetMoney("bank")
	local amount = tonumber(amount)
	local toAccount = toAccount
	local RecieverDetails

	if balance < amount then
		return cb(false) --not enough money
	end

	if transferType == "contact" then
		local phoneNumber = toAccount.number
		RecieverDetails = MySQL.query.await(
			"SELECT citizenid, money FROM players where phone_number = ?",
			{ phoneNumber }
		)
	end

	if transferType == "accountNumber" then
		for _, v in pairs(bannedCharacters) do --strip bad characters
			toAccount = string.gsub(toAccount, "%" .. v, "")
		end
		local query = '%"account":"' .. toAccount .. '"%'
		RecieverDetails = MySQL.query.await("SELECT citizenid, money FROM players WHERE charinfo LIKE ?", { query })
	end

	if RecieverDetails[1] ~= nil then
		local Reciever = QBCore.Functions.GetPlayerByCitizenId(RecieverDetails[1].citizenid)
		Player.Functions.RemoveMoney("bank", amount)
		if Reciever ~= nil then
			Reciever.Functions.AddMoney("bank", amount)
		else
			local RecieverMoney = json.decode(RecieverDetails[1].money)
			RecieverMoney.bank = (RecieverMoney.bank + amount)
			MySQL.update(
				"UPDATE players SET money = ? WHERE citizenid = ?",
				{ json.encode(RecieverMoney), RecieverDetails[1].citizenid }
			)
		end
		cb(Player.Functions.GetMoney("bank"))
	else
		cb(false) --no account found
	end
end)

AddEventHandler("QBCore:Server:OnMoneyChange", function(source, moneytype, amount, type)
	if moneytype == "bank" then
		local Player = QBCore.Functions.GetPlayer(source)
		local balance = Player.Functions.GetMoney("bank")
		TriggerClientEvent("npwd:qb-banking:updateMoney", source, balance)
	end
end)

--qbcore bill command from qb-phone
QBCore.Commands.Add('bill', 'Bill A Player', {{name = 'id', help = 'Player ID'}, {name = 'amount', help = 'Fine Amount'}}, false, function(source, args)
    local biller = QBCore.Functions.GetPlayer(source)
    local billed = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local amount = tonumber(args[2])
    if biller.PlayerData.job.name == "police" or biller.PlayerData.job.name == 'ambulance' or biller.PlayerData.job.name == 'mechanic' then
        if billed ~= nil then
            if biller.PlayerData.citizenid ~= billed.PlayerData.citizenid then
                if amount and amount > 0 then
                    local invoiceId = MySQL.insert.await(
                        'INSERT INTO phone_invoices (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
                        {billed.PlayerData.citizenid, amount, biller.PlayerData.job.name,
                         biller.PlayerData.charinfo.firstname, biller.PlayerData.citizenid})
					local invoiceData = {
						id = invoiceId,
						citizenid = billed.PlayerData.citizenid,
						amount = amount,
						society = biller.PlayerData.job.name,
						sender = biller.PlayerData.charinfo.firstname,
						sendercitizenid = biller.PlayerData.citizenid
					}
                    TriggerClientEvent('npwd:qb-banking:newInvoice', billed.PlayerData.source, invoiceData)
                    TriggerClientEvent('QBCore:Notify', source, 'Invoice Successfully Sent', 'success')
                    TriggerClientEvent('QBCore:Notify', billed.PlayerData.source, 'New Invoice Received')
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Must Be A Valid Amount Above 0', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', source, 'You Cannot Bill Yourself', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', source, 'Player Not Online', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'No Access', 'error')
    end
end)