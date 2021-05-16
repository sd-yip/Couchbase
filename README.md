Couchbase Docker Image
===

```sh
docker pull sdyip/couchbase:community-5.1.1
```

## Environment Variables
| Name                         | Default Value                                        |
| ---                          | ---                                                  |
| MEMORY_QUOTA                 | `300`                                                |
| INDEX_MEMORY_QUOTA           | `300`                                                |
| ENABLE_QUERY                 | `true`                                               |
| ENABLE_SEARCH                | `false`                                              |
| ENABLE_INDEX                 | `true`                                               |
| USERNAME                     | `Administrator`                                      |
| PASSWORD                     | `password`                                           |
| INDEX_STORAGE                | `forestdb` (Community Edition) or `memory_optimized` |
| BUCKET                       | None                                                 |
| BUCKET_TYPE                  | `couchbase`                                          |
| BUCKET_QUOTA                 | `100`                                                |
| BUCKET_REPLICAS              | `0`                                                  |
| BUCKET_INDEX_REPLICAS        | `false`                                              |
| BUCKET_ENABLE_FLUSH          | `false`                                              |
| BUCKET_EJECTION_METHOD       | `valueOnly`                                          |
| BUCKET_PASSWORD              | *PASSWORD*                                           |
| BUCKET_ENABLE_PRIMARY_INDEX  | *ENABLE_INDEX*                                       |
| REST_PORT                    | `8091`                                               |
| ENABLE_STDOUT_LOG_FORWARDING | `false`                                              |
