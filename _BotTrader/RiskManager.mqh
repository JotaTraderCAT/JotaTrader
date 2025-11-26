//+------------------------------------------------------------------+
//| Risk management module                                           |
//+------------------------------------------------------------------+
#ifndef __BOTTRADER_RISK_MQH__
#define __BOTTRADER_RISK_MQH__

#include <_BotTrader/Parameters.mqh>

//+------------------------------------------------------------------+
//| Initialization / Deinitialization                                |
//+------------------------------------------------------------------+
bool RiskManagerInit()
  {
   return(true);
  }

void RiskManagerDeinit()
  {
  }

//+------------------------------------------------------------------+
//| Spread helpers                                                   |
//+------------------------------------------------------------------+
double CurrentSpreadPoints()
  {
   const string symbol=ActiveSymbol();
   double bid=0.0;
   double ask=0.0;
   double point=0.0;

   if(!SymbolInfoDouble(symbol,SYMBOL_BID,bid) ||
      !SymbolInfoDouble(symbol,SYMBOL_ASK,ask) ||
      !SymbolInfoDouble(symbol,SYMBOL_POINT,point))
     {
      Print("[Risk] Failed to retrieve spread components for ",symbol,
            ". Error: ",GetLastError());
      return(0.0);
     }

   if(point<=0.0 || bid<=0.0 || ask<=0.0)
      return(0.0);

   return((ask-bid)/point);
  }

//+------------------------------------------------------------------+
//| Spread check                                                     |
//+------------------------------------------------------------------+
bool RiskManagerCheckSpread()
  {
   double spread_points=CurrentSpreadPoints();
   if(spread_points<=0.0)
     {
      Print("[Risk] Invalid spread measurement. SpreadPoints=",spread_points);
      return(false);
     }

   if(Inp_SpreadMaximo>0 && spread_points>Inp_SpreadMaximo)
     {
      PrintFormat("[Risk] Spread too high: %.1f pts (max=%.1f)",spread_points,
                  (double)Inp_SpreadMaximo);
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Daily loss limit                                                 |
//+------------------------------------------------------------------+
bool RiskManagerCheckDailyLoss()
  {
   if(Inp_MaxDailyLossPct<=0.0)
      return(true);

   datetime now_time=TimeCurrent();
   MqlDateTime tm;
   TimeToStruct(now_time,tm);
   tm.hour=0; tm.min=0; tm.sec=0;
   datetime day_start=StructToTime(tm);

   if(!HistorySelect(day_start,now_time))
     {
      Print("[Risk] HistorySelect failed. Error: ",GetLastError());
      return(true);
     }

   double daily_profit=0.0;
   uint deals_total=HistoryDealsTotal();
   for(uint i=0;i<deals_total;i++)
     {
      ulong deal_ticket=HistoryDealGetTicket(i);
      if(deal_ticket==0)
         continue;

      long magic=HistoryDealGetInteger(deal_ticket,DEAL_MAGIC);
      if(magic!=Inp_Magic)
         continue;

      int entry_type=(int)HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
      if(entry_type!=DEAL_ENTRY_IN && entry_type!=DEAL_ENTRY_OUT)
         continue;

      double profit=HistoryDealGetDouble(deal_ticket,DEAL_PROFIT)+
                    HistoryDealGetDouble(deal_ticket,DEAL_SWAP)+
                    HistoryDealGetDouble(deal_ticket,DEAL_COMMISSION);
      daily_profit+=profit;
     }

   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double allowed_loss=balance*(Inp_MaxDailyLossPct/100.0)*(-1.0);
   if(daily_profit<=allowed_loss)
     {
      Print("[Risk] Daily loss limit reached. Profit: ",daily_profit," Allowed: ",allowed_loss);
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Stop loss normalization                                          |
//+------------------------------------------------------------------+
double RiskManagerNormalizeStopLoss(const double entry_price,const double sl_price,const bool is_buy)
  {
   const string symbol=ActiveSymbol();
   double normalized_sl=sl_price;

   double point=0.0;
   if(!SymbolInfoDouble(symbol,SYMBOL_POINT,point))
     {
      Print("[Risk] Failed to obtain point size for ",symbol,". Error: ",GetLastError());
      return(sl_price);
     }
   long digits=0;
   if(!SymbolInfoInteger(symbol,SYMBOL_DIGITS,digits))
      digits=_Digits;

   normalized_sl=NormalizeDouble(normalized_sl,(int)digits);

   long stop_level=0;
   if(!SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL,stop_level))
      stop_level=0;

   double min_stop=stop_level*point;
   if(is_buy)
     {
      if(entry_price-normalized_sl<min_stop)
         normalized_sl=entry_price-min_stop;
     }
   else
     {
      if(normalized_sl-entry_price<min_stop)
         normalized_sl=entry_price+min_stop;
     }

   return(normalized_sl);
  }

//+------------------------------------------------------------------+
//| Lot calculation                                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(const double entry_price,const double stop_loss)
  {
   const string symbol=ActiveSymbol();
   double min_lot=0.0;
   double max_lot=0.0;
   double lot_step=0.0;

   if(!SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN,min_lot) ||
      !SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX,max_lot) ||
      !SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP,lot_step))
     {
      Print("[Risk] Failed to load trading volume limits for ",symbol,". Error: ",GetLastError());
      return(0.0);
     }

   if(Inp_UseFixedLot)
     {
      double lot=NormalizeDouble(Inp_FixedLot,2);
      if(lot<min_lot)
         lot=min_lot;
      if(lot>max_lot)
         lot=max_lot;
      return(lot);
     }

   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amount=balance*(Inp_RiskPercent/100.0);

   double tick_value=0.0;
   double tick_size=0.0;
   if(!SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE,tick_value) ||
      !SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE,tick_size))
     {
      Print("[Risk] Failed to obtain tick data for ",symbol,". Error: ",GetLastError());
      return(0.0);
     }

   if(tick_value<=0.0 || tick_size<=0.0)
     {
      Print("[Risk] Invalid tick data for lot calculation");
      return(0.0);
     }

   double stop_distance=entry_price-stop_loss;
   if(stop_distance<=0.0)
     {
      Print("[Risk] Invalid stop distance for lot calculation");
      return(0.0);
     }

   double money_per_point=tick_value/tick_size;
   double point=0.0;
   if(!SymbolInfoDouble(symbol,SYMBOL_POINT,point))
     {
      Print("[Risk] Failed to obtain point size for lot calculation. Error: ",GetLastError());
      return(0.0);
     }

   double stop_points=stop_distance/point;
   if(stop_points<=0.0)
     {
      Print("[Risk] Stop points <= 0");
      return(0.0);
     }

   double lot=risk_amount/(stop_points*money_per_point);
   lot=MathFloor(lot/lot_step)*lot_step;
   lot=NormalizeDouble(lot,2);

   if(lot<min_lot)
      lot=min_lot;
   if(lot>max_lot)
      lot=max_lot;

   return(lot);
  }
#endif // __BOTTRADER_RISK_MQH__
//+------------------------------------------------------------------+
