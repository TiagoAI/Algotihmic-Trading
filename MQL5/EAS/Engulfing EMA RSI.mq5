input double LotSize = 0.01;
input int ema_period = 200;
input int rsi_period = 15;
input double RiskBenefit = 2;
input double max_loss = 0.0015;

#include <trade/trade.mqh>
CTrade trade;
ulong trade_ticket = 0;
bool time_passed = true;
double entry_price;

int EMA;
int RSI;
double EMA_Array[];
double RSI_Array[];
MqlRates velas[];

bool cond_buy() {
    return velas[1].close > velas[1].open && 
           velas[0].close < velas[0].open && 
           velas[0].open < velas[1].close && 
           velas[0].close > velas[1].open &&
           RSI_Array[0] < 50;
}

bool cond_sell() {
    return velas[1].close < velas[1].open && 
           velas[0].close > velas[0].open && 
           velas[0].open > velas[1].close && 
           velas[0].close < velas[1].open &&
           RSI_Array[0] > 50;
}

void AdjustStopLoss()
{
    // Obtener el balance actual de la cuenta
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    // Calcular el 2% del balance
    double riskAmount = accountBalance * max_loss / 100;

    // Iterar sobre todas las posiciones abiertas
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        // Obtener el identificador de la posición
        ulong positionTicket = PositionGetTicket(i);

        // Obtener información de la posición
        if (PositionSelectByTicket(positionTicket))
        {
            // Obtener detalles de la posición
            double currentStopLoss = PositionGetDouble(POSITION_SL);
            double currentTakeProfit = PositionGetDouble(POSITION_TP);
            
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double lotSize = PositionGetDouble(POSITION_VOLUME);

            // Calcular el valor en puntos del 2% del balance
            double pointValue = riskAmount / (lotSize * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE));

            // Calcular el nuevo nivel de Stop Loss
            double newStopLoss = entryPrice;
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
                newStopLoss -= pointValue;
            }
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                newStopLoss += pointValue;
            }

            // Comparar y ajustar el Stop Loss si es necesario
            if ((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && currentStopLoss < newStopLoss) ||
                (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && currentStopLoss > newStopLoss))
            {
                // Modificar el Stop Loss de la posición
                if (!trade.PositionModify(positionTicket, newStopLoss,currentTakeProfit))
                {
                    Print("Error al modificar el Stop Loss de la posición: ", GetLastError());
                }
            }
        }
    }
}



int OnInit() {
    EMA = iMA(_Symbol, PERIOD_CURRENT, ema_period, 0, MODE_EMA, PRICE_CLOSE);
    RSI = iRSI(_Symbol, PERIOD_CURRENT, rsi_period, PRICE_CLOSE);
    ArraySetAsSeries(EMA_Array, true);
    ArraySetAsSeries(RSI_Array, true);
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}

void OnTick() {
    CopyBuffer(EMA, 0, 0, 3, EMA_Array);
    CopyBuffer(RSI, 0, 0, 3, RSI_Array);
    CopyRates(_Symbol, _Period, 0, 3, velas);

    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);

    // Verificar si hay una posición abierta pero no hay tickets comerciales
    if (trade_ticket != 0 && PositionsTotal() == 0) {
        trade_ticket = 0;
    }
       
    if (trade_ticket == 0 && time_passed == true) { 
        if (cond_sell()) 
        {
            entry_price = Bid;
            double sl = Bid + (velas[0].open - Bid) * 2;
            double tp = Bid - ((velas[0].open - Bid) * 2) * RiskBenefit;
            trade_ticket = trade.Sell(LotSize, _Symbol, Bid, sl, tp);
            AdjustStopLoss();
            time_passed = false;     
            EventSetTimer(PeriodSeconds(PERIOD_CURRENT) * 1);
        }
        else if (cond_buy()) 
        {
            entry_price = Ask;
            double sl = Ask - (Ask - velas[0].open) * 2;
            double tp = Ask + ((Ask - velas[0].open) * 2) * RiskBenefit;
            trade_ticket = trade.Buy(LotSize, _Symbol, Ask, sl, tp);
            AdjustStopLoss();
            time_passed = false;     
            EventSetTimer(PeriodSeconds(PERIOD_CURRENT) * 1);
        }
    }
}

void OnTimer() { 
    time_passed = true; 
}
