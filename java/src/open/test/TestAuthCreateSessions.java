package com.easydataservices.open.test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.logging.Logger;
import com.easydataservices.open.auth.AuthControlDao;
import com.easydataservices.open.auth.AuthAttributesDao;
import com.easydataservices.open.auth.StoreSession;
import com.easydataservices.open.auth.StoreAttribute;
import com.easydataservices.open.test.TestAuthBootstrap;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * AUTH Service test payload class for creating new sessions and attributes.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthCreateSessions extends TestAuthPayload {
  private static final String className = TestAuthCreateSessions.class.getName();
  private static final Logger logger = Logger.getLogger(className);
  private AuthControlDao authControlDao;
  private AuthAttributesDao authAttributesDao;
  private String sessionIdPrefix;
  private String authNamePrefix;

  public void init(TestAuthBootstrap bootstrap) throws Exception {
    logger.finer(() -> String.format("ENTRY %s %s", this, bootstrap));
    authControlDao = new AuthControlDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    authAttributesDao = new AuthAttributesDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    sessionIdPrefix = bootstrap.getPayloadPrefix1() + "_";
    if (!bootstrap.getPayloadPrefix2().trim().equals("")) {
      authNamePrefix = bootstrap.getPayloadPrefix2() + "_";
    }
    logger.finer(() -> String.format("RETURN %s", this));
  }

  public void payload(int rangeValue, int iteration) throws Exception {
    logger.finer(() -> String.format("ENTRY %s %s %s", this, rangeValue, iteration));
    ArrayList<StoreAttribute> attributeList = new ArrayList<StoreAttribute>();
    String sessionId = sessionIdPrefix + rangeValue;
    String authName = null;
    if (authNamePrefix != null) {
      authName = authNamePrefix + rangeValue;
    }
    StoreSession session = new StoreSession(sessionId);
    authControlDao.addSession(
      session.getSessionId(),
      new Object[] {
        null,
        authName,
        null,
        session.getPropertiesJson()
      }
    );
    int attributeCount = rangeValue % 6;
    for (int i = 0; i <= attributeCount; i++) {
      int size = ((int) Math.pow(2, i + 1)) * 32000;
      char[] charArray = new char[size];
      Arrays.fill(charArray, '*');
      String attributeName = "ATTRIBUTE_" + (i + 1);
      StoreAttribute attribute = new StoreAttribute(attributeName);
      attribute.setObject("large object:" + new String(charArray) + attributeName);
      attributeList.add(attribute);
    }
    authAttributesDao.saveAttributes(sessionId, attributeList);
    logger.info("Created session " + session.getSessionId() + " with " + attributeCount + " attributes.");
    logger.finer(() -> String.format("RETURN %s", this));
  }
}
