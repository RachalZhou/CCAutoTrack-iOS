# 《iOS全埋点解决方案》读书笔记
![cover](book_cover.jpg)

推荐神策数据王灼洲老师的新书[《iOS全埋点解决方案》](https://item.jd.com/12867068.html)，这本书读起来干货满满。本人在阅读过程中随书籍实现了SDK代码，为加深印象，又特以笔记记之。以下为笔记内容。

## 数据采集SDK

主流的埋点方式：代码埋点、全埋点、可视化埋点

新建framework、workspace、project（demo）进行SDK编写

设置基本预置属性，demo集成SDK

## 应用的启动和退出

全埋点可采集的4个事件：**$AppStart**、 **$AppEnd**、 **$AppViewScreen**、 **$AppClick**

5种应用程序常见的状态：Not running、Inactive、Active、Background、Suspended

通过监听*UIApplicationDidFinishLaunchingNotification*、*UIApplicationWillResignActiveNotification*、*UIApplicationDidBecomeActiveNotification*、*UIApplicationDidEnterBackgroundNotification*这些本地通知实现方法回调，添加 $AppStart 和 $AppEnd 事件

**被动启动**：iOS7以后新增功能，由系统触发，自动进入后台运行

几种后台模式：Location updates、Newsstand downloads、 External accessory communication、Remote notifications等等

通过UIApplication的backgroundTimeRemaining属性判断应用是否为被动启动，选择是否触发 $AppStartPassively 事件

## 页面浏览事件

根据UIViewController的生命周期`-viewDidAppear:`方法，使用Method Swizzling交换方法实现，添加$AppViewScreen事件

配置黑名单，选择性过滤不需要追踪的页面

获取页面标题的顺序navigationItem.titleView --> navigationItem.title

遗留问题：

* 1.热启动没有触发$AppViewScreen
* 2.子类若重写`-viewDidAppear:`方法一定要实现`[super viewDidAppear:animated]`

## 控件点击事件

iOS中控件都是UIControl类或其子类，基于**Target-Action**模式

**方案一**：使用Method Swizzling交换UIApplication的`-sendAction:to:from:forEvent`方法，添加$AppClick事件

优化：

* 1.获取控件类型、内容，根据事件响应者链获取控件所在页面
* 2.添加对UISwitch、UISlider等控件的支持

**方案二**：使用Method Swizzling交换UIView的`-didMoveToSuperview`方法，在交换的方法里给控件添加一组UIControlEventTouchDown类型的Target-Action，在Action里触发$AppClick事件

注意：UIControl并没有实现`-didMoveToSuperview`方法，这个方法是从它的父类UIView中继承而来的。所以在交换方法之前，先在当前类中添加需要交换的方法，并在添加成功之后获取新的方法指针

优化：支持UISwitch、UISegmentedControl、UIStepper等控件

**方案总结**：二者都是基于Target-Action模式，各有优劣。方案一的缺点是若一个控件添加了多个Target-Action，会多次触发$AppClick事件。方案二为控件添加了一个默认的触发类型Action，有可能会引入一些无法预料的问题。根据实际情况选择方案。

## UITableVIew和UICollectionView点击事件

**方法交换**

* 思路：使用Method Swizzling交换UITableView的`-setDelegate`方法，得到delegate，然后交换`-tableView:didSelectRowAtIndexPath:`方法，添加统计点击的事件
* 优点：Method Swizzling技术成熟，易理解，性能较高
* 缺点：容易造成冲突

**动态代理**

* 思路：给实现`-tableView:didSelectRowAtIndexPath:`方法的delegate类创建子类，先运行子类的`-tableView:didSelectRowAtIndexPath:`方法，在方法中先调用原始类的实现，然后添加统计点击的事件
* 优点：无侵入，无冲突，比较稳妥
* 缺点：动态创建子类会有内存和性能消耗

**消息转发**

NSProxy作为一个委托代理对象，将消息转发给一个真实的对象或者自己加载过的对象

NSProxy相对NSObject更适合实现消息转发的优势：（1）NSProxy类实现了包括NSObject协议在内所需要的基础方法；（2）通过NSObject类实现代理不会自动转发NSObject协议中的方法；（3）通过NSObject类实现代理不会自动转发NSObject类别中的方法

* 思路：使用NSProxy的子类获取delegate，重载`-methodSignatureForSelector:`和`forwardInvocation:`方法实现消息转发，在转发的方法里添加统计点击的事件
*  注意：使用关联对象给UIScrollView类别中新增delegateProxy属性，用于保留代理对象，以免发生程序奔溃
* 优点：充分利用消息转发机制，性能较好，写法优雅
* 缺点：容易与其他消息拦截的第三方库冲突

## 手势采集 
使用Method Swizzling分别交换`-initWithTarget:target:action:`和`-addTarget:action:`方法，采用Target-Action的方式，触发$AppClick事件

## 用户标识
### 登录之前
**现状**：苹果公司为了维护整个生态的健康发展，极力阻止唯一标识一台iOS设备，现有政策下能做的是努力寻找最优的解决方案

* UDID：iOS5后已禁止获取，可通过设备连接Xcode或安装蒲公英的描述文件获取
* UUID：每次获取都会生成新的
* MAC地址：入网设备地址，iOS7后获取会得到一个固定值
* IDFA：广告标识符，通过AdSupport.framework获取，还原设置、还原设备、限制广告追踪均会影响
* IDFV：应用开发商标识符，卸载同一开发商的所有应用再重装会得到一个新的值
* IMEI：国际移动设备身份码，iOS5之后不再允许获取

**最佳实践**：获取唯一标识优先级顺序：IDFA --> IDFV --> UUID，利用Keychain存储

### 登录之后
添加login方法，存储loginId

## 时间相关

**统计事件持续时长**

实现`-trackTimerStart`和`-trackTimerEnd`方法，注意使用systemUptime代替当前时间

**事件的暂停和恢复**

实现`-trackTimerPause`和`-trackTimerResume`方法

**后台状态下的事件时长**

进入后台调用`-trackTimerPause`方法，进入前台调`用-trackTimerResume`方法

**$AppEnd事件时长**

进入前台调用`-trackTimerStart`方法，进入后台调用`-trackTimerEnd`方法

**$AppViewScreen事件时长**

存在来不及执行`-viewWillDisappear`的情况和浏览子页面覆盖的情况

## 数据存储
对比内存缓存和磁盘缓存

了解沙盒机制（原理是重定向技术），了解沙盒路径

**对比文件缓存和数据库缓存**

* 写入性能：SQLite数据库优于文件缓存
* 读取性能：情况对比较复杂（每次写入的数据量越大，文件缓存的性能就越好，若兼顾读写就采用SQLite数据库缓存，文件缓存不够灵活，比如很难对单条数据进行读写操作）

**文件缓存**

* 方式一：通过NSKeyedArchiver对字典对象进行归档并写入文件
* 方式二：通过NSJSONSerialization将字典转换成字符串并写入文件（性能更佳）

实现`read`、`save`、`delete`功能

* 多线程优化（解决卡主线程问题）：新建串行队列，dispatch_async函数执行readAll、save、delete功能，dispatch_sync函数执行allEvents功能
* 内存优化（解决无网环境下内存占用过大问题）：设置本地可缓存的最大事件条数，超过最大值就删除最旧的数据

**数据库缓存**

使用SQLite数据库实现插入、查询、删除数据的操作

* 缓存sqlite3_stmt优化：减少资源大量消耗
* 缓存事件总条数优化：方便查询和删除前遇到本地为0就直接退出

数据库缓存相对文件缓存要复杂，需要一定的SQL基础，以及sqlite3 API学习成本，不过更加灵活，也具有极高的性能

## 数据同步
作为通用的数据采集SDK，要求尽量不能去依赖任何第三方库

NSURLSession及其相关类的介绍

**数据同步策略**

目的：一方面降低SDK使用难度，另一方面确保了数据的正确性、完整性和及时性

* 策略一：客户端本地已缓存的事件超过一定条数时同步
* 策略二：客户端每隔一定的时间同步一次
* 策略三：应用程序进入后台时尝试同步本地已缓存的所有数据

## 奔溃采集

**NSException异常**：通过NSSetUncaughtExceptionHandler全局函数实现，收集堆栈信息，注意传递UncaughtExceptionHandler

**Unix信号异常**：Mach异常转换为Unix信号异常，了解常见Unix信号，注册信号处理函数，获取当前堆栈信息

采集异常时 $AppEnd 事件：由于发生异常时 $AppStart 和 $AppEnd 并非成对出现，需要补发 $AppEnd 事件






