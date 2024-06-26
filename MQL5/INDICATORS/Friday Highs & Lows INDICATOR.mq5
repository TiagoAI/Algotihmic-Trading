//+------------------------------------------------------------------+
//|                                                  Previous Friday |
//|                        Copyright 2022, MetaQuotes Ltd.           |
//|                     http://www.metaquotes.net                    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "http://www.metaquotes.net"
#property version   "1.00"
#property indicator_chart_window
#property strict
#property indicator_buffers 3 // Declare one buffer for each line
#property indicator_plots 3

#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2
#property indicator_color1 clrRed
#property  indicator_label1 "PreviousWeekFridayHigh"

#property indicator_type2 DRAW_LINE
#property indicator_style2 STYLE_SOLID
#property indicator_width2 2
#property indicator_color2 clrGreen
#property  indicator_label2 "PreviousWeekFridayLow"

#property indicator_type3 DRAW_LINE
#property indicator_style3 STYLE_SOLID
#property indicator_width3 2
#property indicator_color3 clrBlue
#property  indicator_label3 "PreviousWeekFridayClose"

double fridayHighBuffer[];
double fridayLowBuffer[];
double fridayCloseBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Link each buffer
   SetIndexBuffer(0, fridayHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, fridayLowBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, fridayCloseBuffer, INDICATOR_DATA);

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
                const int &spread[])
{
   MqlDateTime DateTimeStructure;

   for (int i = rates_total - 1; i >= 0; i--)
   {
      TimeToStruct(time[i], DateTimeStructure); // Convert time to structure
      int dayOfWeek = DateTimeStructure.day_of_week; // Get the day of the week for the current bar
      
      if (dayOfWeek == 5) // Check if it's Friday
      {
         int shift = iBarShift(_Symbol,PERIOD_D1,time[i]);
         double highMax = iHigh(_Symbol,PERIOD_D1,shift);
         double lowMin = iLow(_Symbol,PERIOD_D1,shift);
         double lastClose = iClose(_Symbol,PERIOD_D1,shift);

         // Set the values in the buffers
         fridayHighBuffer[i] = highMax;
         fridayLowBuffer[i] = lowMin;
         fridayCloseBuffer[i] = lastClose;
      }
      else
      {
         fridayHighBuffer[i] = EMPTY_VALUE; // Clear buffer if not Friday
         fridayLowBuffer[i] = EMPTY_VALUE;
         fridayCloseBuffer[i] = EMPTY_VALUE;
      }
   }
   return(rates_total);
}
