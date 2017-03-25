package com.darylstlaurent.climbingdb.client;

import com.google.gwt.core.client.JavaScriptObject;

// Area        : "Pawtuckaway"
// Cliff       : "Devil's Den"
// Grade       : "V7"
// GradeBucket : "V07"
// GradeSort   : 7
// Route       : "Up in Smoke"
// RouteType   : "Boulder"
// SendDate    : "2016-10-23"
// Style       : "redpoint"
// YearBucket  : 0

/**
 * Overlay type to wrap a JavaScript send object
 * @author Daryl St. Laurent
 *
 */
public class Send extends JavaScriptObject {
  
  // Overlay types require protected zero-argument constructors
  protected Send() { }
  
  // Getters for data (must be public and final)
  public final native String getArea()        /*-{ return this.Area        }-*/;
  public final native String getCliff()       /*-{ return this.Cliff       }-*/;
  public final native String getGrade()       /*-{ return this.Grade       }-*/;
  public final native String getGradeBucket() /*-{ return this.GradeBucket }-*/;
  public final native String getGradeSort()   /*-{ return this.GradeSort   }-*/;
  public final native String getRoute()       /*-{ return this.Route       }-*/;
  public final native String getRouteType()   /*-{ return this.RouteType   }-*/;
  public final native String getSendDate()    /*-{ return this.SendDate    }-*/;
  public final native String getStyle()       /*-{ return this.Style       }-*/;
  public final native String getYearBucket()  /*-{ return this.YearBucket  }-*/;

  
}
