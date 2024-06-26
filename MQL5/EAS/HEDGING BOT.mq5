//+------------------------------------------------------------------+
//|                                            SimultaneousEA.mq5   |
//|                        Copyright 2024, Company Name               |
//|                                       http://www.company.net     |
//+------------------------------------------------------------------+
#property copyright "Tiago"
#property link      "https://www.mql5.com"
#property version   "1.00"

// Include standard library for trading operations
#include <trade/trade.mqh>
CTrade trade; // Trade object for executing trade operations

// Input parameters for the EA
input double LotSize = 0.1; // The size of each trade
input int TakeProfitPips = 10; // The profit target in pips
input int Multiplier = 2; // The multiplier for hedging iterations

// Global variables to keep track of trade tickets and entry prices
int ticket_buy = -1; // Ticket number for the buy position
int ticket_sell = -1; // Ticket number for the sell position
double entryPriceAsk; // Entry price for the buy position
double entryPriceBid; // Entry price for the sell position
int iteration = 1; // Counter for the number of hedging iterations

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize EA
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function - called on every new tick                  |    
//+------------------------------------------------------------------+
void OnTick()
{
    // Retrieve current ASK and BID prices with appropriate precision
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);

    // Check if there are no open positions
    if (ticket_buy == -1 && ticket_sell == -1)
    {
        // Open simultaneous buy and sell positions
        entryPriceAsk = Ask; // Store the entry ASK price
        entryPriceBid = Bid; // Store the entry BID price
        ticket_buy = trade.Buy(LotSize, _Symbol, Ask); // Open buy position
        ticket_sell = trade.Sell(LotSize, _Symbol, Bid); // Open sell position
    }
    
    else
    {
        // Check Pips, Take profit and new multiplied order
        if (ticket_buy != -1 && ticket_sell != -1)
        {
            if (Ask >= entryPriceAsk + (TakeProfitPips * 10 * _Point))
            {
                trade.PositionClose(ticket_buy);
                ticket_sell = trade.Sell(LotSize * Multiplier, _Symbol, Bid);
                entryPriceBid = Bid;
                ticket_buy = -1; // Reset ticket
                iteration = 1;
            }
            else if (Bid <= entryPriceBid - (TakeProfitPips * 10 * _Point))
            {
                trade.PositionClose(ticket_sell);
                ticket_buy = trade.Buy(LotSize * Multiplier, _Symbol, Ask);
                entryPriceAsk = Ask;
                ticket_sell = -1; // Reset ticket
                iteration = 1;
            }
        }
        
        // Check for hedging with multiplier and iteration
        if (ticket_sell != -1 && ticket_buy == -1)
        {
            if (CheckOverallProfit())
            {
                trade.PositionClose(_Symbol);
                ticket_sell = -1; // Reset ticket left
                iteration = 1;
            }
            else if (Bid >= entryPriceBid + (TakeProfitPips * 10 * _Point * Multiplier * iteration))
            {
                entryPriceBid = Bid;
                iteration *= Multiplier;
                ticket_sell = trade.Sell(LotSize * iteration, _Symbol, Bid);
            }
        }
        
        if (ticket_sell == -1 && ticket_buy != -1)
        {
            if (CheckOverallProfit())
            {
                trade.PositionClose(_Symbol);
                ticket_buy = -1; // Reset ticket left
                iteration = 1;
            }
            else if (Ask <= entryPriceAsk - (TakeProfitPips * 10 * _Point * Multiplier * iteration))
            {
                entryPriceAsk = Ask;
                iteration *= Multiplier;
                ticket_buy = trade.Buy(LotSize * iteration, _Symbol, Ask);
                
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check overall profit and close all positions if profit is positive|
//+------------------------------------------------------------------+
bool CheckOverallProfit()
{
    double totalProfit = 0;
    int positionsTotal = PositionsTotal();
    
    // Sum the profit of all open positions
    for (int i = 0; i < positionsTotal; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            totalProfit += PositionGetDouble(POSITION_PROFIT);
        }
    }
    
    // If total profit is positive, close all positions
    if (totalProfit > 0)
    {
        for (int i = 0; i < positionsTotal; i++)
        {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
        return true;
    }
    return false;
}