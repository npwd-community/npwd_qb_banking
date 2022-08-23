local QBCore = exports['qb-core']:GetCoreObject()

RegisterNUICallback("npwd:qb-banking:getBalance", function(_, cb)
  QBCore.Functions.TriggerCallback("npwd:qb-banking:GetBankBalance", function(result)
    if result then 
      cb({ status = "ok", data = result })
    else
      cb({status = "error"})
    end
  end)
end)

RegisterNUICallback("npwd:qb-banking:getAccountNumber", function(_, cb)
  QBCore.Functions.TriggerCallback("npwd:qb-banking:getAccountNumber", function(result)
    if result then 
      cb({ status = "ok", data = result })
    else
      cb({status = "error"})
    end
  end)
end)

RegisterNUICallback("npwd:qb-banking:getContacts", function(_, cb)
  QBCore.Functions.TriggerCallback("npwd:qb-banking:getContacts", function(result)
    if result then 
      cb({ status = "ok", data = result })
    else
      cb({status = "error"})
    end
  end)
end)

RegisterNUICallback("npwd:qb-banking:transferMoney", function(data, cb)
  QBCore.Functions.TriggerCallback("npwd:qb-banking:transferMoney", function(result)
    if result then 
      cb({ status = "ok", data = result })
    else
      cb({status = "error"})
    end
  end, data.amount, data.toAccount, data.transferType)
end)

RegisterNetEvent('npwd:qb-banking:updateMoney', function(balance)
    exports.npwd:sendUIMessage('npwd:qb-banking:updateMoney', {balance})
end)