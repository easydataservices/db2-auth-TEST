package com.easydataservices.open.test;

import com.easydataservices.open.auth.AuthControlDao;
import com.easydataservices.open.test.TestAuthBootstrap;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * AUTH Service test payload class for testing the CONTROL.REMOVE_SESSION procedure.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthRemoveSession extends TestAuthPayload {
  private AuthControlDao authControlDao;
  private String sessionIdPrefix;

  public void init(TestAuthBootstrap bootstrap) throws Exception {
    authControlDao = new AuthControlDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    sessionIdPrefix = bootstrap.getPayloadUniqueId() + "_";
  }

  public void payload(int iteration) throws Exception {
    authControlDao.removeSession(sessionIdPrefix + iteration);
  }
}