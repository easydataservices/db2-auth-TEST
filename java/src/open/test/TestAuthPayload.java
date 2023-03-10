package com.easydataservices.open.test;

import com.easydataservices.open.test.TestAuthBootstrap;

/**
 * Abstract test payload class. AUTH Service test classes must extend this to implement the payload method.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public abstract class TestAuthPayload {
  /**
   * Initialise class objects using supplied bootstrap data.
   * @param bootstrap Bootstrap data,
   */
  public abstract void init(TestAuthBootstrap bootstrap) throws Exception;

  /**
   * Execute payload for specfied occurrence.
   * @param rangeId Range value (typically used to differentiate sessions).
   * @param iteration Iteration, starting at 1 for first call and incrementing by 1 for each subsequent call.
   */
  public abstract void payload(int rangeValue, int iteration) throws Exception;
}
