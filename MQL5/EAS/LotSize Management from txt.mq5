// Declare global variables to store symbol and lot size
string g_symbol;
double g_lotSize;

//+------------------------------------------------------------------+
//| Expert advisor initialization function                           |
//+------------------------------------------------------------------+
int OnInit()
{
    // Obtener el símbolo actual
    string currentSymbol = _Symbol;
    Print("Current Symbol: ", currentSymbol);

    // Read the configuration file
    if(!ReadConfigFile("Lots.txt", currentSymbol))
    {
        Print("Failed to read configuration file.");
        return INIT_FAILED;
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert advisor deinitialization function                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Perform any necessary cleanup when stopping the EA
}

//+------------------------------------------------------------------+
//| Expert advisor tick function                                     |
//+------------------------------------------------------------------+
void OnTick()
{
    // Place trading logic based on the values read from the file
    // Example: Open a trade using g_symbol and g_lotSize
    // Example:
    // double price = SymbolInfoDouble(g_symbol, SYMBOL_BID);
    // if(price > 0)
    // {
    //     double lotSize = g_lotSize;
    //     if(lotSize > 0)
    //     {
    //         int ticket = OrderSend(g_symbol, OP_BUY, lotSize, price, 0, 0, 0, "MyOrder", 0, 0, clrNONE);
    //         if(ticket < 0)
    //             Print("Error opening order: ", GetLastError());
    //     }
    // }
}

// Function to read the configuration file
bool ReadConfigFile(string fileName, string currentSymbol)
{
    // Open the text file
    int fileHandle = FileOpen(fileName, FILE_READ,",");
    if(fileHandle != INVALID_HANDLE)
    {
        string line;
        // Read each line of the file
        while(!FileIsEnding(fileHandle))
        {
            line = FileReadString(fileHandle);
            if(StringLen(line) > 0)
                ProcessLine(line, currentSymbol);
                
        }
        FileClose(fileHandle);
        return true;
    }
    else
    {
        Print("Error opening file ", fileName, ": ", GetLastError());
        return false;
    }
}


// Function to process a line of the file
void ProcessLine(string line, string currentSymbol)
{
    string symbol;
    double lotSize;
    StringReplace(line, " ", ""); // Remove white spaces
 
    int equalPos = StringFind(line, "=");
    
    if(equalPos != -1)
    {
        symbol = StringSubstr(line, 0, equalPos);
        if(symbol == currentSymbol)
        {
            lotSize = StringToDouble(StringSubstr(line, equalPos + 1));
            
            Print("Symbol: ", symbol, ", Lot Size: ", lotSize);
            
            // Store symbol and lot size in global variables
            g_symbol = symbol;
            g_lotSize = lotSize;
        }
        else
        {
           Print("Error Not Symbol Match");
        }
    }
}