local QBCore = exports["qb-core"]:GetCoreObject()
local bannedCharacters = { "%", "$", ";" }

QBCore.Functions.CreateCallback("npwd:qb-banking:GetBankBalance", function(source, cb)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local balance = Player.Functions.GetMoney("bank")
	if not balance then
		cb(false)
	end
	cb(balance)
end)

QBCore.Functions.CreateCallback("npwd:qb-banking:getAccountNumber", function(source, cb)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local accountNumber = Player.PlayerData.charinfo.account
	if not accountNumber then
		cb(false)
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
		cb(false)
	end
	cb(contacts)
end)

QBCore.Functions.CreateCallback("npwd:qb-banking:transferMoney", function(source, cb, amount, toAccount, transferType)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local balance = Player.Functions.GetMoney("bank")
	local amount = amount
	local toAccount = toAccount
	local RecieverDetails

	if balance < amount then
		cb(false) --not enough money
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
			amount = string.gsub(amount, "%" .. v, "")
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
