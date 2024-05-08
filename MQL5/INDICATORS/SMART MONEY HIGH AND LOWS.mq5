#property indicator_chart_window

#property indicator_buffers 2
#property indicator_plots 2

#property indicator_label1 "High"
#property indicator_color1 clrGreen
#property indicator_style1 STYLE_SOLID
#property indicator_type1 DRAW_ARROW

#property indicator_label2 "Low"
#property indicator_color2 clrRed
#property indicator_style2 STYLE_SOLID
#property indicator_type2 DRAW_ARROW

input int Depth = 20;

double highs[],lows[];

int OnInit()
  {
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   
   SetIndexBuffer(0,highs,INDICATOR_DATA);
   SetIndexBuffer(1,lows,INDICATOR_DATA);
   
   ArraySetAsSeries(highs,true);
   ArraySetAsSeries(lows,true);
   
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   
   PlotIndexGetInteger(0,PLOT_ARROW_SHIFT,-10);
   PlotIndexGetInteger(1,PLOT_ARROW_SHIFT,10);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]){
  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   
   int limit = rates_total-prev_calculated;
   limit = MathMin(limit,rates_total-Depth*2-1);
   
   for(int i = limit; i > 0; i--){
      highs[i] = EMPTY_VALUE;
      lows[i] = EMPTY_VALUE;
      
      if(i+Depth == ArrayMaximum(high,i,Depth*2)){
         highs[i+Depth] = high[i+Depth];    
      }
      if(i+Depth == ArrayMinimum(low,i,Depth*2)){
         lows[i+Depth] = low[i+Depth];    
      }
   
   }
   
   return rates_total;
  }
//+------------------------------------------------------------------+
