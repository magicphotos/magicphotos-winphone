import bb.cascades 1.0
import ImageEditor 1.0

Page {
    id: sketchPreviewPage

    property string imageFile: ""

    function openImage(image_file) {
        imageFile = image_file;

        sketchPreviewGenerator.openImage(image_file);
    }

    paneProperties: NavigationPaneProperties {
        backButton: ActionItem {
            onTriggered: {
                navigationPane.pop();
            }
        }
    }

    actions: [
        ActionItem {
            id:                  helpActionItem
            title:               qsTr("Help")
            imageSource:         "images/help.png"
            ActionBar.placement: ActionBarPlacement.OnBar
            
            property Page helpPage: null
            
            onTriggered: {
                navigationPane.push(helpPageDefinition.createObject());
            }

            attachedObjects: [
                ComponentDefinition {
                    id:     helpPageDefinition
                    source: "HelpPage.qml"
                }
            ]
        }
    ]
    
    Container {
        background: Color.Black

        layout: StackLayout {
        }

        Container {
            horizontalAlignment: HorizontalAlignment.Center 
            background:          Color.Transparent

            layoutProperties: StackLayoutProperties {
                spaceQuota: 1
            }
            
            layout: DockLayout {
            }

            ImageView {
                id:                  previewImageView
                horizontalAlignment: HorizontalAlignment.Center 
                verticalAlignment:   VerticalAlignment.Center
                scalingMethod:       ScalingMethod.AspectFit

                attachedObjects: [
                    SketchPreviewGenerator {
                        id: sketchPreviewGenerator
                        
                        property int activityIndicatorUsageCounter: 0
                        
                        onImageOpened: {
                            gaussianRadiusSlider.enabled = true;
                            applyButton.enabled          = true;
                        }

                        onImageOpenFailed: {
                            gaussianRadiusSlider.enabled = false;
                            applyButton.enabled          = false;

                            MessageBox.showToast(qsTr("Could not open image"));
                        }
                        
                        onGenerationStarted: {
                            activityIndicatorUsageCounter = activityIndicatorUsageCounter + 1;
                            
                            if (activityIndicatorUsageCounter === 1) {
                                activityIndicator.visible = true;
                                activityIndicator.start();
                            }
                        }

                        onGenerationFinished: {
                            if (activityIndicatorUsageCounter === 1) {
                                activityIndicator.stop();
                                activityIndicator.visible = false;
                            }
                            
                            if (activityIndicatorUsageCounter > 0) {
                                activityIndicatorUsageCounter = activityIndicatorUsageCounter - 1;
                            }
                        }

                        onNeedRepaint: {
                            previewImageView.image = image;                            
                        }
                    }
                ]
            }

            ActivityIndicator {
                id:                  activityIndicator
                preferredWidth:      256
                preferredHeight:     256
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment:   VerticalAlignment.Center
                visible:             false
            }
        }

        Slider {
            id:                  gaussianRadiusSlider
            horizontalAlignment: HorizontalAlignment.Center 
            fromValue:           4
            toValue:             18
            value:               11
            enabled:             false

            layoutProperties: StackLayoutProperties {
                spaceQuota: -1
            }
            
            onValueChanged: {
                sketchPreviewGenerator.radius = value;
            }
        }

        Button {
            id:                  applyButton
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment:   VerticalAlignment.Bottom
            text:                qsTr("Apply")
            enabled:             false
            
            layoutProperties: StackLayoutProperties {
                spaceQuota: -1
            }
            
            onClicked: {
                var page = sketchPageDefinition.createObject();

                navigationPane.push(page);

                page.openImage(imageFile, gaussianRadiusSlider.value);
            }

            attachedObjects: [
                ComponentDefinition {
                    id:     sketchPageDefinition
                    source: "SketchPage.qml"
                }
            ]
        }
    }
}
