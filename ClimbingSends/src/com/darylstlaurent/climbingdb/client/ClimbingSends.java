package com.darylstlaurent.climbingdb.client;

import com.google.gwt.core.client.EntryPoint;
import com.google.gwt.core.client.JsArray;
import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.ui.Button;
import com.google.gwt.user.client.ui.FlexTable;
import com.google.gwt.user.client.ui.RootPanel;
import com.google.gwt.user.client.ui.VerticalPanel;

public class ClimbingSends implements EntryPoint {
  private VerticalPanel mainPanel = new VerticalPanel();
  private FlexTable sendTable = new FlexTable();
  private Button testButton = new Button("Test");
  private JsArray<Send> sends = getSends();
  
  /**
   * Entry point method
   */
  public void onModuleLoad() {
    
    // create test table for send data
    sendTable.setText(0, 0, "Route");
    sendTable.setText(0, 1, "Grade");
    for (int i = 0; i < sends.length(); i++) {
      Send send = sends.get(i);
      sendTable.setText(i+1, 0, send.getRoute());
      sendTable.setText(i+1, 1, send.getGrade());
    }
    
    // assemble main panel
    mainPanel.add(testButton);
    mainPanel.add(sendTable);
    
    // associate main panel with HTML host page
    RootPanel.get("climbingSendsContainer").add(mainPanel);
    
    // handle clicks on test button
    testButton.addClickHandler(new ClickHandler() {
      public void onClick(ClickEvent event) {
        Window.alert(sends.get(0).getArea());
      }
    });
    
  }
  
  public final native JsArray<Send> getSends() /*-{
    return $wnd.sends;
  }-*/;
  
  
}
