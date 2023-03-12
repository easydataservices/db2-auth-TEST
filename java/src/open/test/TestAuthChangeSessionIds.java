package com.easydataservices.open.test;

import java.util.logging.Logger;
import com.easydataservices.open.auth.AuthControlDao;
import com.easydataservices.open.auth.AuthSessionDao;
import com.easydataservices.open.test.TestAuthBootstrap;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * AUTH Service test payload class for updating session identifiers.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthChangeSessionIds extends TestAuthPayload {
  private static final String className = TestAuthChangeSessionIds.class.getName();
  private static final Logger logger = Logger.getLogger(className);
  private AuthSessionDao authSessionDao;
  private AuthControlDao authControlDao;
  private String sessionIdPrefix;
  private String newSessionIdPrefix;

  public void init(TestAuthBootstrap bootstrap) throws Exception {
    logger.finer(() -> String.format("ENTRY %s %s", this, bootstrap));
    authSessionDao = new AuthSessionDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    authControlDao = new AuthControlDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    sessionIdPrefix = bootstrap.getPayloadPrefix1() + "_";
    newSessionIdPrefix = bootstrap.getPayloadPrefix2() + "_";
    logger.finer(() -> String.format("RETURN %s", this));
  }

  public void payload(int rangeValue, int iteration) throws Exception {
    logger.finer(() -> String.format("ENTRY %s %s %s", this, rangeValue, iteration));
    String sessionId = sessionIdPrefix + rangeValue;
    String newSessionId = newSessionIdPrefix + rangeValue;
    authControlDao.changeSessionId(sessionId, newSessionId);
    logger.info("Updated session identifier " + sessionId + " to " + newSessionId + ".'");
    logger.finer(() -> String.format("RETURN %s", this));
  }
}
