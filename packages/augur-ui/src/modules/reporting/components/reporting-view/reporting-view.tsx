import React from "react";
import { Route, Switch } from "react-router-dom";

import ReportingDisputeMarkets from "modules/reporting/containers/reporting-dispute-markets";
import ReportingReportMarkets from "modules/reporting/containers/reporting-report-markets";
import ReportingResolved from "modules/reporting/containers/reporting-resolved";
import makePath from "modules/routes/helpers/make-path";
import Reports from "modules/portfolio/containers/reports";
import AuthenticatedRoute from "modules/routes/components/authenticated-route/authenticated-route";

import {
  REPORTING_DISPUTE_MARKETS,
  REPORTING_REPORT_MARKETS,
} from "modules/routes/constants/views";

const ReportingView = p => (
  <section>
    <Switch>
      <Route
        path={makePath(REPORTING_DISPUTE_MARKETS)}
        component={ReportingDisputeMarkets}
      />
      <Route
        path={makePath(REPORTING_REPORT_MARKETS)}
        component={ReportingReportMarkets}
      />
    </Switch>
  </section>
);

export default ReportingView;
