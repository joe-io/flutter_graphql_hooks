library flutter_graphql_hooks;

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

export 'package:flutter_graphql_hooks/flutter_graphql_hooks.dart';
export 'package:graphql_flutter/graphql_flutter.dart';

GraphQLClient useGraphQLClient() {
  var context = useContext();
  return GraphQLProvider.of(context).value;
}

typedef FutureCallback<T> = Future<T> Function();

class RefetchableQueryResult extends QueryResult {

  RefetchableQueryResult({
      dynamic data,
      List<GraphQLError> errors,
      bool loading,
      bool stale,
      bool optimistic = false,
      this.refetch,
  }): super(
    data: data,
    errors: errors,
    loading: loading,
    stale: stale,
    optimistic: optimistic
  );

  FutureCallback<void> refetch;
}

RefetchableQueryResult useQuery(QueryOptions options) {

  var client = useGraphQLClient();
  var result = useState(RefetchableQueryResult(loading: true));

  Future<RefetchableQueryResult> fetch() {
    return client.query(options)
      .then( (qr) => result.value = RefetchableQueryResult(
          loading: qr.loading,
          data: qr.data,
          errors: qr.errors,
          stale: qr.stale,
          optimistic: qr.optimistic,
          refetch: () {         
            // set loading to true
            result.value = RefetchableQueryResult(
              loading: true,
              data: qr.data,
              refetch: fetch,
            );
            // Update fetchPolicy so that we ensure a netowrk request, instead of using the cache
            options.fetchPolicy = FetchPolicy.networkOnly;
            // refetch the existing query
            return fetch();
            // return Future.value(RefetchableQueryResult(loading: false));
          },
        ));
  };

  useEffect(() { fetch(); }, [options.toKey()]);

  return result.value;
}

