/*
 Copyright 2017 Vector Creations Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <MatrixKit/MatrixKit.h>

typedef NS_ENUM(NSInteger, ShareDataSourceMode)
{
    DataSourceModePeople,
    DataSourceModeRooms
};


@interface ShareDataSource : MXKRecentsDataSource

- (instancetype)initWithMode:(ShareDataSourceMode)dataSourceMode;

/**
 Returns the cell data at the index path
 
 @param indexPath the index of the cell
 @return the MXKRecentCellData instance if it exists
 */
- (MXKRecentCellData *)cellDataAtIndexPath:(NSIndexPath *)indexPath;

@end
