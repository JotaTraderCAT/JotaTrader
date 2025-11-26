#pragma once
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <BotTrader/Parameters.mqh>

CTrade         g_trade;
CPositionInfo  g_position;

//+------------------------------------------------------------------+
//| Initialization / Deinitialization                                |
//+------------------------------------------------------------------+
bool TradeManagerInit()
  {
   g_trade.SetExpertMagicNumber((long)Inp_Magic);
   g_trade.SetDeviationInPoints(Inp_SlippagePoints);
   return(true);
  }

void TradeManagerDeinit()
  {
  }

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
bool HasOpenPosition()
  {
   if(g_position.Select(ActiveSymbol()))
     {
      if(g_position.Magic()==(long)Inp_Magic)
         return(true);
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| Order operations                                                 |
//+------------------------------------------------------------------+
bool OpenBuy(const double lot,const double sl,const double tp)
  {
   const string symbol=ActiveSymbol();
   double ask=0.0;
   if(!SymbolInfoDouble(symbol,SYMBOL_ASK,ask))
     {
      Print("[Trade] Failed to get ask price. Error: ",GetLastError());
      return(false);
     }

   g_trade.SetExpertMagicNumber((long)Inp_Magic);
   g_trade.SetDeviationInPoints(Inp_SlippagePoints);

   bool result=g_trade.Buy(lot,symbol,ask,sl,tp,Inp_TradeComment);
   if(!result)
     {
      Print("[Trade] Buy order failed. Error: ",GetLastError());
      return(false);
     }

   return(true);
  }

bool ClosePosition(const string reason)
  {
   if(!g_position.Select(ActiveSymbol()))
      return(false);

   if(g_position.Magic()!=(long)Inp_Magic)
      return(false);

   double close_price=0.0;
   if(!SymbolInfoDouble(ActiveSymbol(),SYMBOL_BID,close_price))
     {
      Print("[Trade] Failed to get bid price for close. Error: ",GetLastError());
      return(false);
     }

   bool result=g_trade.PositionClose(ActiveSymbol(),close_price,Inp_SlippagePoints);
   if(!result)
     {
      Print("[Trade] Failed to close position. Reason: ",reason," Error: ",GetLastError());
      return(false);
     }
   return(true);
  }

bool UpdateStopLoss(const double new_sl)
  {
   if(!g_position.Select(ActiveSymbol()))
      return(false);

   if(g_position.Magic()!=(long)Inp_Magic)
      return(false);

   double current_tp=g_position.TakeProfit();
   bool result=g_trade.PositionModify(ActiveSymbol(),new_sl,current_tp);
   if(!result)
     {
      Print("[Trade] Failed to update stop loss. Error: ",GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
