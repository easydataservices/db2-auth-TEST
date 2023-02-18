package com.easydataservices.open.test;

import com.easydataservices.open.auth.AuthControlDao;
import com.easydataservices.open.auth.StoreSession;
import com.easydataservices.open.test.TestAuthBootstrap;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * AUTH Service test payload class for testing the CONTROL.ADD_SESSION procedure.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthAddSession extends TestAuthPayload {
  private AuthControlDao authControlDao;
  private String sessionIdPrefix;

  public void init(TestAuthBootstrap bootstrap) throws Exception {
    authControlDao = new AuthControlDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    sessionIdPrefix = bootstrap.getPayloadUniqueId() + "_";
  }

  public void payload(int iteration) throws Exception {
    StoreSession session = new StoreSession(sessionIdPrefix + iteration);
    authControlDao.addSession(
      session.getSessionId(), 
      new Object[] {
        null,
        "user_" + iteration,
        null,
        "{\"comment\":\"test data\"}"
      }
    );
  }
}