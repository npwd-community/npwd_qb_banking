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
      cb({ status = "ok", data = tonumber(result) })
    else
      cb({status = "error"})
    end
  end, data.amount, data.toAccount, data.transferType)
end)

RegisterNUICallback("npwd:qb-banking:getInvoices", function(_, cb)
  QBCore.Functions.TriggerCallback("npwd:qb-banking:getInvoices", function(result)
    if result then 
      cb({ status = "ok", data = result })
    else
      cb({status = "error"})
    end
  end)
end)

RegisterNUICallback("npwd:qb-banking:declineInvoice", function(data, cb)
  QBCore.Functions.TriggerCallback("npwd:qb-banking:declineInvoice", function(result)
    if result then 
      cb({ status = "ok"})
    else
      cb({status = "error"})
    end
  end, data)
end)

RegisterNUICallback("npwd:qb-banking:payInvoice", function(data, cb)
  QBCore.Functions.TriggerCallback("npwd:qb-banking:payInvoice", function(result)
    if result then 
      cb({ status = "ok", data = result})
    else
      cb({status = "error"})
    end
  end, data)
end)

RegisterNetEvent('npwd:qb-banking:updateMoney', function(balance)
  exports.npwd:sendUIMessage({type = "npwd:qb-banking:updateMoney", payload = balance})
end)

RegisterNetEvent('npwd:qb-banking:newInvoice', function(data)
  exports.npwd:sendUIMessage({type = "npwd:qb-banking:newInvoice", payload = data})
end)