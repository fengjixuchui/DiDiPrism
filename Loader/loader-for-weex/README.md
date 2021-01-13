
# Weex Loader For DiDiPrism

A webpack loader for Weex project with DiDiPrism.

![npm](https://img.shields.io/npm/v/weex-loader-for-didiprism)
![npm](https://img.shields.io/npm/dw/weex-loader-for-didiprism)

这是一个`Webpack Loader`，它用在基于`Vue`的`Weex`项目中，通过该`Loader`生成在`小桔棱镜`中使用的属性，辅助小桔棱镜做标签元素的唯一ID校验。

## 快速上手

### 安装

该 `Loader` 已上传到 `npm` 仓库，使用下面的命令安装：

```bash
npm i --save weex-loader-for-didiprism
```

### 使用

安装之后，就可以在`Webpack`配置中使用它了，针对`.vue`做语法转换及解析。配置文件示例代码如下：

```javascript
const webpackConfig = {
  entry: {
    index: './example/main.js'
  },
  mode: 'production', // 'development',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: options.dev ? '[name].js' : '[name].js?[chunkhash]',
    chunkFilename: '[id].js?[chunkhash]',
    publicPath: options.dev ? '/assets/' : publicPath
  },
  module: {
    rules: [{
      test: /\.vue$/,
      use: [
        'vue-loader',
        // 注意：需要将 weex-loader-for-prism 放到数组的靠后位置，因为Webpack是按照从后往前的顺序执行loader
        'weex-loader-for-didiprism'
      ]
    },
    {
      test: /\.js$/,
      use: ['babel-loader'],
      exclude: /node_modules/
    }]
  }
}
```

## 效果

该`Loader`要实现的效果，是给带有点击事件的标签，自动添加一些小桔棱镜的属性，方便Native侧做元素的唯一标识。

比如，我们业务代码里写的是这样一个组件：

```vue
<template>
  <div @click="onClick">This is a subtitle.</div>
</template>
<script>
export default {
  data: () => ({

  }),
  methods: {
    onClick() {
      console.log('---click the subtitle---')
    }
  }
}
</script>
<style lang="less" scoped>

</style>
```

`Webpack`在经过`weex-loader-for-didiprism`和`vue-loader`的打包之后，会将上面的Vue组件转换成这样一段AST代码：

```javascript
var render = function() {
  var _vm = this
  var _h = _vm.$createElement
  var _c = _vm._self._c || _h
  return _c(
    "div",
    {
      staticClass: "content-title",
      attrs: { prismFunctionName: "onClick", prismClassName: "content-title" },
      on: { click: _vm.onClick }
    },
    [_vm._v("This is a title.")]
  )
}
```

有点击事件监听的标签，会多出两个属性：`prismFunctionName` 和 `prismClassName`，它们就是给小桔棱镜Native侧使用的属性。这样，开发者就不用手动添加这些属性，主需要关注业务逻辑即可。

## 协议

<img alt="Apache-2.0 license" src="https://www.apache.org/img/ASF20thAnniversary.jpg" width="128">
