//+------------------------------------------------------------------+
//|                                               GraphicalPanel.mqh |
//|                                                  Sergey_s_altaya |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Sergey_s_altaya"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== Panel Inputs ====";
static input int InpPanelWidth = 260;                       // width in pixel (ширина в пикселях)
static input int InpPanelHeight = 230;                      // height in pixel (высота в пикселях)
static input int InpPanelFontSize = 13;                     // font size (размер шрифта)
static input color InpPanelTxtColor = clrWhiteSmoke;      // text color  (цвет текста)

//+------------------------------------------------------------------+
//| Class CGraphicalPanel                                            |
//+------------------------------------------------------------------+
class CGraphicalPanel : public CAppDialog
(
    private:

        // private methods
        bool CreatePanel();

    public:

        void CGraphicalPanel ();
        void ~CGraphicalPanel ();
        bool Oninit ();

        // cahrt event handler
        void PanelChartEvent (const int id, const long &lparam, const double &dparam, const string &sparam);
);

// constructor
void CGraphicalPanel::CGraphicalPanel(void){}

// deconstructor
void CGraphicalPanel::~CGraphicalPanel(void){}

bool CGraphicalPanel::Oninit(void){

    // create panel
    if(!this.CreatePanel()){return false;}

    return true;

}

bool CGraphicalPanel:: CreatePanel(void){

    // create dialog panel
    this.Create(NULL,"Time Range EA",0,0,0,InpPanelWidth,InpPanelHeight);

    // run panel
    if(!Run())

    return true;

}


14.15

